#!/usr/bin/env perl

use strict;
use warnings;
use IO::Socket::INET;
use POSIX qw(strftime);

# Configuration
my $STATE_FILE = "/tmp/heartbeat.state";
my $LOG_FILE = "/tmp/heartbeat.log";
my $TARGET_SERVER = "TARGET_SERVER_PLACEHOLDER";  # Format: IP:PORT

# Get all local IP addresses with interface names
sub get_all_ips {
    my @interfaces;

    # Get list of all network interfaces
    my @all_interfaces = `ifconfig -l 2>/dev/null`;
    chomp(@all_interfaces);
    my @interface_names = split(/\s+/, $all_interfaces[0] || '');

    # For each interface, get its IP address
    foreach my $iface (@interface_names) {
        my $ip = `ifconfig $iface 2>/dev/null | grep 'inet ' | grep -v 127.0.0.1 | awk '{print \$2}'`;
        chomp($ip);

        # Only add interfaces that have an IP address
        if ($ip) {
            push @interfaces, {
                name => $iface,
                ip => $ip
            };
        }
    }

    return @interfaces;
}

# Get last success timestamp
sub get_last_success_time {
    if (-f $STATE_FILE) {
        open(my $fh, '<', $STATE_FILE) or return 0;
        my $timestamp = <$fh>;
        close($fh);
        chomp($timestamp);
        return $timestamp || 0;
    }
    return 0;
}

# Save success timestamp
sub save_success_time {
    my $timestamp = time();
    open(my $fh, '>', $STATE_FILE) or die "Failed to write state file: $!";
    print $fh $timestamp;
    close($fh);
}

# Calculate next sending interval (seconds)
sub calculate_interval {
    my $last_success = get_last_success_time();
    my $current_time = time();
    my $time_since_success = $current_time - $last_success;

    # If never succeeded, use 1 minute interval
    return 60 if $last_success == 0;

    # After 5 hours (18000s), change to 1 day (86400s)
    return 86400 if $time_since_success >= 18000;

    # After 10 minutes (600s), change to 1 hour (3600s)
    return 3600 if $time_since_success >= 600;

    # Default: 1 minute (60s)
    return 60;
}

# Format interval to readable string
sub format_interval {
    my ($interval) = @_;
    return "1 day" if $interval == 86400;
    return "1 hour" if $interval == 3600;
    return "1 minute";
}

# Get current timestamp string
sub get_timestamp {
    return strftime("%a %b %e %H:%M:%S %Z %Y", localtime());
}

# Write log
sub write_log {
    my ($message) = @_;
    open(my $fh, '>>', $LOG_FILE) or die "Failed to write log: $!";
    print $fh get_timestamp() . ": $message\n";
    close($fh);
}

# Send HTTP POST request
sub send_http_post {
    my ($host, $port, $path, $json_data) = @_;

    # Create socket connection
    my $socket = IO::Socket::INET->new(
        PeerHost => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 10,
    );

    unless ($socket) {
        return (0, "Connection failed: $!");
    }

    # Build HTTP POST request
    my $content_length = length($json_data);
    my $http_request = "POST $path HTTP/1.1\r\n";
    $http_request .= "Host: $host:$port\r\n";
    $http_request .= "Content-Type: application/json\r\n";
    $http_request .= "Content-Length: $content_length\r\n";
    $http_request .= "Connection: close\r\n";
    $http_request .= "\r\n";
    $http_request .= $json_data;

    # Send request
    print $socket $http_request;

    # Read response
    my $response = '';
    while (my $line = <$socket>) {
        $response .= $line;
        last if $line =~ /^\r?\n$/;  # End of HTTP headers
    }

    close($socket);

    # Check response status code
    if ($response =~ /HTTP\/\d\.\d\s+(\d+)/) {
        my $status_code = $1;
        if ($status_code >= 200 && $status_code < 300) {
            return (1, "HTTP $status_code");
        } else {
            return (0, "HTTP $status_code");
        }
    }

    return (0, "Invalid response");
}

# Send heartbeat message
sub send_heartbeat {
    my @interfaces = get_all_ips();

    unless (@interfaces) {
        write_log("Failed to get any local IP addresses");
        return 0;
    }

    # Parse target server
    my ($host, $port) = split(':', $TARGET_SERVER);
    unless ($host && $port) {
        write_log("Invalid target server config: $TARGET_SERVER");
        return 0;
    }

    # Build JSON message body with all interfaces
    my @interface_json;
    foreach my $iface (@interfaces) {
        push @interface_json, qq({"name": "$iface->{name}", "ip": "$iface->{ip}"});
    }
    my $interfaces_str = join(', ', @interface_json);
    my $json_data = qq({"interfaces": [$interfaces_str]});

    # Build log message with all IPs
    my @ip_list = map { "$_->{name}:$_->{ip}" } @interfaces;
    my $ip_summary = join(', ', @ip_list);

    # Send HTTP POST request
    my ($success, $message) = send_http_post($host, $port, '/', $json_data);

    if ($success) {
        save_success_time();
        write_log("Send success - IPs: $ip_summary (restored to 1 minute interval)");
        return 1;
    } else {
        write_log("Send failed - IPs: $ip_summary, Error: $message");
        return 0;
    }
}

# Main loop
write_log("Heartbeat service started, target: $TARGET_SERVER");

while (1) {
    # Calculate current interval
    my $interval = calculate_interval();
    my $interval_text = format_interval($interval);

    # Send heartbeat
    my $success = send_heartbeat();

    # If send failed, log the interval
    unless ($success) {
        write_log("Next attempt in: $interval_text");
    }

    # Wait for next send
    sleep($interval);
}

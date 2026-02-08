#!/usr/bin/env perl

use strict;
use warnings;
use IO::Socket::INET;
use POSIX qw(strftime);

# Configuration
my $DEFAULT_PORT = 7777;
my $LOG_FILE = "/tmp/heartbeat_server.log";

# Get port from command line argument
my $port = $ARGV[0] || $DEFAULT_PORT;

# Get current timestamp string
sub get_timestamp {
    return strftime("%Y-%m-%d %H:%M:%S", localtime());
}

# Write log
sub write_log {
    my ($message) = @_;
    open(my $fh, '>>', $LOG_FILE) or warn "Failed to write log: $!";
    if ($fh) {
        print $fh get_timestamp() . " - $message\n";
        close($fh);
    }
    print get_timestamp() . " - $message\n";  # Also print to terminal
}

# Simple JSON parser (only handles our format: {"ip": "x.x.x.x"})
sub parse_json {
    my ($json_str) = @_;
    my %result;

    # Remove whitespace and newlines
    $json_str =~ s/\s+//g;

    # Match "ip":"value" format
    if ($json_str =~ /"ip"\s*:\s*"([^"]+)"/) {
        $result{ip} = $1;
    }

    return \%result;
}

# Handle HTTP request
sub handle_request {
    my ($client_socket, $client_addr) = @_;

    my $request = '';
    my $headers = '';
    my $body = '';
    my $content_length = 0;

    # Read request headers
    while (my $line = <$client_socket>) {
        $headers .= $line;
        last if $line =~ /^\r?\n$/;  # Empty line marks end of headers

        # Get Content-Length
        if ($line =~ /^Content-Length:\s*(\d+)/i) {
            $content_length = $1;
        }

        # Get request line
        if ($line =~ /^(GET|POST|HEAD)\s+(\S+)\s+HTTP/) {
            $request = $1;
        }
    }

    # Read request body (if any)
    if ($content_length > 0) {
        read($client_socket, $body, $content_length);
    }

    # Get client IP (note: unpack_sockaddr_in returns (port, ip) not (ip, port))
    my ($client_port, $packed_ip) = unpack_sockaddr_in($client_addr);
    my $client_ip = inet_ntoa($packed_ip);

    # Handle different request methods
    if ($request eq 'POST') {
        # Parse JSON data
        my $data = parse_json($body);

        if ($data->{ip}) {
            write_log("Received heartbeat - From: $client_ip, Reported IP: $data->{ip}");
        } else {
            write_log("Received POST request - From: $client_ip, Data: $body");
        }

        # Send response
        print $client_socket "HTTP/1.1 200 OK\r\n";
        print $client_socket "Content-Type: application/json\r\n";
        print $client_socket "Connection: close\r\n";
        print $client_socket "\r\n";
        print $client_socket "{\"status\":\"ok\"}\r\n";

    } elsif ($request eq 'GET') {
        # Handle GET request
        write_log("Received GET request - From: $client_ip");

        my $response_body = "<html><body><h1>Heartbeat Server</h1><p>Server is running</p></body></html>";
        print $client_socket "HTTP/1.1 200 OK\r\n";
        print $client_socket "Content-Type: text/html\r\n";
        print $client_socket "Content-Length: " . length($response_body) . "\r\n";
        print $client_socket "Connection: close\r\n";
        print $client_socket "\r\n";
        print $client_socket $response_body;

    } elsif ($request eq 'HEAD') {
        # Handle HEAD request
        print $client_socket "HTTP/1.1 200 OK\r\n";
        print $client_socket "Content-Type: text/html\r\n";
        print $client_socket "Connection: close\r\n";
        print $client_socket "\r\n";

    } else {
        # Unknown request
        print $client_socket "HTTP/1.1 400 Bad Request\r\n";
        print $client_socket "Connection: close\r\n";
        print $client_socket "\r\n";
    }

    close($client_socket);
}

# Main program
print "=" x 50 . "\n";
print "Heartbeat Server\n";
print "=" x 50 . "\n";
print "Port: $port\n";
print "Log: $LOG_FILE\n";
print "Press Ctrl+C to stop server\n";
print "=" x 50 . "\n\n";

# Create socket server
my $server = IO::Socket::INET->new(
    LocalPort => $port,
    Type      => SOCK_STREAM,
    Reuse     => 1,
    Listen    => 10,
) or die "Failed to create server: $!";

write_log("Server started, listening on port $port");

# Main loop: accept connections
while (1) {
    my $client_socket = $server->accept();
    next unless $client_socket;

    my $client_addr = getpeername($client_socket);

    # Handle request
    eval {
        handle_request($client_socket, $client_addr);
    };

    if ($@) {
        write_log("Error handling request: $@");
    }
}

close($server);

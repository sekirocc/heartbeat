# 心跳服务器 (Heartbeat Server)

纯 Perl 实现的 HTTP 服务器，用于接收心跳消息。

## 特性

- **纯 Perl**: 仅使用核心模块（IO::Socket::INET、POSIX）
- **零依赖**: 无需安装任何 CPAN 包
- **轻量级**: 简单高效的 HTTP 服务器实现
- **日志记录**: 自动记录所有心跳消息

## 快速启动

### 使用默认端口 (7777)

```bash
./heartbeat_server.pl
```

### 指定端口

```bash
./heartbeat_server.pl 8080
```

### 后台运行

```bash
nohup ./heartbeat_server.pl 7777 > /tmp/server.out 2>&1 &
```

## 功能说明

### 支持的 HTTP 方法

#### POST - 接收心跳消息
接收 JSON 格式的心跳数据：

```bash
curl -X POST http://localhost:7777 \
  -H "Content-Type: application/json" \
  -d '{"ip": "192.168.1.100"}'
```

服务器会：
- 解析 JSON 数据
- 记录客户端 IP 和报告的 IP
- 返回 200 OK 响应

#### GET - 健康检查
```bash
curl http://localhost:7777
```

返回 HTML 页面显示服务器状态。

#### HEAD - 服务器存活检查
```bash
curl -I http://localhost:7777
```

返回响应头，不包含响应体。

## 日志

### 日志位置
```
/tmp/heartbeat_server.log
```

### 查看日志

```bash
# 查看最近的日志
tail -20 /tmp/heartbeat_server.log

# 实时查看日志
tail -f /tmp/heartbeat_server.log
```

### 日志格式

```
2026-02-08 11:30:15 - 服务器启动，监听端口 7777
2026-02-08 11:30:20 - 收到心跳 - 来自: 192.168.1.53, 报告IP: 192.168.1.53
2026-02-08 11:31:20 - 收到心跳 - 来自: 192.168.1.53, 报告IP: 192.168.1.53
```

## 管理

### 查找服务器进程

```bash
ps aux | grep heartbeat_server.pl
```

### 停止服务器

```bash
# 找到进程 ID
ps aux | grep heartbeat_server.pl

# 停止进程
kill <PID>

# 或者强制停止
pkill -f heartbeat_server.pl
```

### 重启服务器

```bash
# 停止
pkill -f heartbeat_server.pl

# 启动
nohup ./heartbeat_server.pl 7777 > /tmp/server.out 2>&1 &
```

## 测试

### 测试 POST 请求

```bash
# 发送心跳消息
curl -X POST http://localhost:7777 \
  -H "Content-Type: application/json" \
  -d '{"ip": "192.168.1.100"}'

# 查看日志确认收到
tail -5 /tmp/heartbeat_server.log
```

### 测试 GET 请求

```bash
curl http://localhost:7777
```

### 使用心跳客户端测试

如果已安装心跳客户端：

```bash
# 修改目标为本机
cd heartbeat
./install.sh localhost:7777
```

## 生产部署

### 使用 systemd (Linux)

创建服务文件 `/etc/systemd/system/heartbeat-server.service`:

```ini
[Unit]
Description=Heartbeat Server
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/bin/perl /opt/heartbeat/heartbeat_server.pl 7777
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
sudo systemctl enable heartbeat-server
sudo systemctl start heartbeat-server
sudo systemctl status heartbeat-server
```

### 使用 launchd (macOS)

创建 plist 文件 `~/Library/LaunchAgents/com.user.heartbeat.server.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.heartbeat.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/perl</string>
        <string>/opt/heartbeat/heartbeat_server.pl</string>
        <string>7777</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/heartbeat_server.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/heartbeat_server.stderr.log</string>
</dict>
</plist>
```

加载服务：
```bash
launchctl load ~/Library/LaunchAgents/com.user.heartbeat.server.plist
```

## 防火墙配置

### macOS
```bash
# 允许端口 7777
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/bin/perl
```

### Linux (iptables)
```bash
sudo iptables -A INPUT -p tcp --dport 7777 -j ACCEPT
```

### Linux (firewalld)
```bash
sudo firewall-cmd --permanent --add-port=7777/tcp
sudo firewall-cmd --reload
```

## 故障排查

### 端口已被占用

```bash
# 查看端口使用情况
lsof -i :7777

# 或使用 netstat
netstat -an | grep 7777
```

### 权限问题

如果使用 1024 以下的端口（如 80），需要 root 权限：

```bash
sudo ./heartbeat_server.pl 80
```

### 查看错误日志

```bash
# 如果后台运行
cat /tmp/server.out

# 或查看服务器日志
tail -50 /tmp/heartbeat_server.log
```

## 系统要求

- Perl 5.10 或更高版本
- 核心模块: IO::Socket::INET, POSIX（系统自带）
- Unix-like 系统 (Linux, macOS, BSD, etc.)

## 性能

- **并发**: 单线程处理，适合轻量级心跳场景
- **内存**: 约 5-10 MB
- **CPU**: 极低占用
- **建议**: 小于 100 个客户端的心跳监控

## 安全建议

1. **限制访问**: 使用防火墙限制只有特定 IP 可以访问
2. **内网使用**: 建议仅在内网使用，不要暴露到公网
3. **监控日志**: 定期检查日志文件大小，防止磁盘被填满
4. **非特权端口**: 使用 1024 以上的端口，避免需要 root 权限

## 许可

自由使用

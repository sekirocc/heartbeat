# 心跳服务 (Heartbeat Service)

macOS 自动启动的心跳监控服务，定期向指定服务器发送本机内网 IP 地址。

**实现**: 纯 Perl 脚本，仅使用核心模块（IO::Socket::INET），无需安装任何 CPAN 包。

## 组件

本项目包含两个部分：

1. **heartbeat.pl** - 心跳客户端（本文档）
   - 安装在客户端机器上
   - 定期发送本机 IP 到服务器

2. **heartbeat_server.pl** - 心跳服务器
   - 安装在服务器上
   - 接收并记录心跳消息
   - 详见 [SERVER_README.md](SERVER_README.md)

## 功能特性

- **自动启动**: 系统启动时自动运行
- **智能频率调整**: 根据网络状态自动调整发送频率
  - 正常: 1分钟一次
  - 10分钟未成功: 降级为1小时一次
  - 5小时未成功: 降级为1天一次
  - 成功后立即恢复为1分钟一次
- **自动重启**: 进程异常退出时自动重启
- **日志记录**: 完整的发送日志和状态记录

## 快速安装

### 前提条件

确保 `heartbeat` 目录包含以下文件：
- `heartbeat.pl` - Perl 心跳脚本（包含占位符）
- `install.sh` - 安装脚本
- `uninstall.sh` - 卸载脚本

**系统要求**:
- macOS 10.10 或更高版本
- Perl 5.10+ (macOS 自带，无需额外安装)

### 方法1: 使用默认配置安装

```bash
cd heartbeat
./install.sh
```

默认目标服务器: `192.168.1.52:7777`

### 方法2: 指定目标服务器安装

```bash
cd heartbeat
./install.sh 192.168.1.100:8080
```

## 安装脚本工作原理

安装脚本执行以下操作：

1. 检查 `heartbeat.pl` 是否存在于同目录
2. 停止已运行的旧服务（如果存在）
3. 创建安装目录 `/opt/heartbeat`（需要 sudo 权限，会提示输入密码）
4. 复制 `heartbeat.pl` 到安装目录
5. 使用 `sed` 替换脚本中的 `TARGET_SERVER_PLACEHOLDER` 为实际目标服务器
6. 创建 LaunchAgent plist 配置文件
7. 加载并启动服务
8. 验证安装结果

**注意**: 因为安装到 `/opt` 目录，安装过程中会要求输入管理员密码。

## 使用说明

### 查看服务状态

```bash
# 查看服务是否运行
launchctl list | grep heartbeat

# 查看实时日志
tail -f /tmp/heartbeat.log

# 查看最近日志
tail -20 /tmp/heartbeat.log

# 查看上次成功时间
cat /tmp/heartbeat.state
```

### 管理服务

```bash
# 停止服务
launchctl unload ~/Library/LaunchAgents/com.user.heartbeat.plist

# 启动服务
launchctl load ~/Library/LaunchAgents/com.user.heartbeat.plist

# 重启服务
launchctl unload ~/Library/LaunchAgents/com.user.heartbeat.plist && \
launchctl load ~/Library/LaunchAgents/com.user.heartbeat.plist
```

### 卸载服务

```bash
cd heartbeat
./uninstall.sh
```

卸载脚本会提示是否删除安装目录和日志文件。

## 文件说明

```
heartbeat/
├── heartbeat.pl        # Perl 心跳服务脚本（含占位符）
├── install.sh          # 安装脚本
├── uninstall.sh        # 卸载脚本
└── README.md          # 说明文档
```

## Perl 实现优势

- **纯 Perl**: 仅使用 Perl 核心模块，无需安装 CPAN 包
- **跨平台**: Perl 在所有 Unix-like 系统中都是标准配置
- **高效**: 内存占用小，性能优秀
- **可靠**: 使用 IO::Socket::INET 直接构建 HTTP 请求，无外部依赖

## 日志文件

- `/tmp/heartbeat.log` - 主日志文件
- `/tmp/heartbeat.state` - 状态文件（记录上次成功时间）
- `/tmp/heartbeat.stdout.log` - 标准输出日志
- `/tmp/heartbeat.stderr.log` - 标准错误日志

## 消息格式

服务会向目标服务器发送 HTTP POST 请求：

```json
{
  "ip": "192.168.1.53"
}
```

请求头：`Content-Type: application/json`

## 频率调整机制

服务会根据发送成功情况自动调整发送频率：

| 状态 | 条件 | 发送频率 |
|------|------|----------|
| 正常 | 最近成功 | 每 1 分钟 |
| 降级1 | 超过 10 分钟未成功 | 每 1 小时 |
| 降级2 | 超过 5 小时未成功 | 每 1 天 |

一旦发送成功，立即恢复为 1 分钟间隔。

## 故障排查

### 服务未运行

```bash
# 检查服务状态
launchctl list | grep heartbeat

# 查看错误日志
cat /tmp/heartbeat.stderr.log

# 手动启动测试
sudo /opt/heartbeat/heartbeat.pl
```

### 无法获取 IP

脚本会尝试以下方式获取本地 IP：
1. en0 接口 (WiFi)
2. en1 接口 (以太网)
3. 所有活跃接口的第一个 IP

如果仍无法获取，请检查网络连接。

### 发送失败

检查：
1. 目标服务器是否可访问
2. 端口是否正确
3. 防火墙设置
4. 网络连接状态

## 系统要求

- macOS 10.10 或更高版本
- Perl 5.10+ (macOS 系统自带)
- 核心 Perl 模块: IO::Socket::INET, POSIX (系统自带，无需安装)

## 许可

自由使用

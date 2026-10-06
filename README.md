# 强制退出所有应用 · macOS

枚举 macOS 前台、后台及菜单栏应用，检查进程所属用户后强制退出，并关闭 Finder 窗口。

## 功能

- 使用 AppKit / JavaScript for Automation 枚举运行应用
- 排除纯系统守护进程
- 仅操作当前用户的进程，不需要 sudo
- 后台执行，终端应用本身也可以被退出

## 使用

使用 macOS 内置 zsh、osascript 和 AppKit。

```bash
chmod +x "一键强制退出所有应用.command"
./"一键强制退出所有应用.command" --help
./"一键强制退出所有应用.command" --dry-run
```

确认预览结果后，可双击 `.command` 文件或在终端不带参数执行。

## 操作边界

`--dry-run` 只打印 PID、bundle identifier 和应用名。实际模式会发送 SIGKILL，不给应用保存文件的机会，可能丢失未保存内容。Finder 不被强杀，改为连续关闭其窗口。

脚本可能结束终端及运行自动化任务的应用。正常退出需求应优先使用各应用自身的退出功能。

## 许可证

[MIT License](LICENSE)。

[简体中文](#简体中文)

devports helps you troubleshoot local TCP port conflicts on Windows. When a dev server reports `EADDRINUSE`, use it to find the process listening on the port and see when the port is released.

## What's in v0.1.0

- Search IPv4 and IPv6 TCP listeners by port or process name. The Simplified Chinese desktop UI shows the listening address, port, process name, and PID.
- Refresh the list every second, pause automatic refresh, or refresh it manually.
- Track a port to see when listening starts, stops, or moves to another process. Tracking continues when the port disappears from the list.
- Run the PowerShell commands `list`, `who`, and `watch` from the source tree.

## Download and try it

Download `devports-win-x64.zip` under **Assets**, extract it, and double-click `devports.exe`. The portable app targets Windows x64 and uses the built-in .NET Framework and Windows PowerShell 5.1. Use `devports-win-x64.zip.sha256` to verify the ZIP.

For a quick test, enter `3000` in the search field and click **跟踪端口** (Track port). Then start, stop, and restart a local service on that port.

This is the first preview. The executable is unsigned. Launching the app, releasing a port, and replacing the listening process were tested on one Windows x64 computer. Timestamps show when the app detected a change. Brief changes between polls may be missed.

If you run into a problem, include your Windows version, the steps to reproduce it, and what happened in a [GitHub issue](https://github.com/shenxuekai/dev-ports/issues).

## 简体中文

devports 是一个用于排查本地 TCP 端口占用的 Windows 小工具。开发服务器报 `EADDRINUSE` 时，可以查看哪个进程正在监听端口，也可以观察它何时释放端口。

### v0.1.0 提供的功能

- 中文窗口列出 IPv4 和 IPv6 的 TCP 监听地址、端口、进程名和 PID，可按端口或进程名搜索。
- 列表默认每秒刷新，也支持暂停自动刷新和手动刷新。
- 选中端口后，记录开始监听、释放监听和进程更换。端口从列表消失后仍会继续跟踪。
- 源码提供 PowerShell 命令行版，可用 `list`、`who` 和 `watch` 查询和跟踪端口。

### 下载和试用

在下方 Assets 下载 `devports-win-x64.zip`，解压后双击 `devports.exe`。便携版面向 Windows x64，使用系统自带的 .NET Framework 和 Windows PowerShell 5.1。可使用同名 `.sha256` 文件核对下载的压缩包。

试用时，可以在搜索框输入 `3000` 并点击「跟踪端口」，再启动、停止和重启一个使用该端口的本地服务。

这是首个试用版本。可执行文件未签名，已在一台 Windows x64 电脑上验证启动、端口释放和更换监听进程。变化记录使用查询时的观测时间，两次查询之间发生并结束的变化可能会被漏掉。

如果遇到问题，欢迎在 [GitHub Issues](https://github.com/shenxuekai/dev-ports/issues) 附上 Windows 版本、操作步骤和实际结果。

devports 是一个用于排查本地 TCP 端口占用的 Windows 小工具。开发服务器报 `EADDRINUSE` 时，可以查看哪个进程正在监听端口，也可以观察它何时释放端口。

## v0.1.0 提供的功能

- 中文窗口列出 IPv4 和 IPv6 的 TCP 监听地址、端口、进程名和 PID，可按端口或进程名搜索。
- 列表默认每秒刷新，也支持暂停自动刷新和手动刷新。
- 选中端口后，记录开始监听、释放监听和进程更换。端口从列表消失后仍会继续跟踪。
- 源码提供 PowerShell 命令行版，可用 `list`、`who` 和 `watch` 查询和跟踪端口。

## 下载和试用

在下方 Assets 下载 `devports-win-x64.zip`，解压后双击 `devports.exe`。便携版面向 Windows x64，使用系统自带的 .NET Framework 和 Windows PowerShell 5.1。可使用同名 `.sha256` 文件核对下载的压缩包。

试用时，可以在搜索框输入 `3000` 并点击「跟踪端口」，再启动、停止和重启一个使用该端口的本地服务。

这是首个试用版本。可执行文件未签名，已在一台 Windows x64 电脑上验证启动、端口释放和更换监听进程。变化记录使用查询时的观测时间，两次查询之间发生并结束的变化可能会被漏掉。

如果遇到问题，欢迎在 [GitHub Issues](https://github.com/shenxuekai/dev-ports/issues) 附上 Windows 版本、操作步骤和实际结果。

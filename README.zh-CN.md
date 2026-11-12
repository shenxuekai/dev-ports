# devports

[English](README.md) · 简体中文

在 Windows 上查找监听 TCP 端口的进程。开发服务器报 `EADDRINUSE` 时，可以用它查出谁占用了端口，也可以观察服务重启时端口是否被释放。

## 窗口版

在 [GitHub Releases](https://github.com/shenxuekai/dev-ports/releases) 下载 `devports-win-x64.zip`，解压后双击 `devports.exe`。便携版面向 Windows x64，使用系统自带的 .NET Framework 和 Windows PowerShell 5.1。

也可以从源码启动。将两个入口脚本、`DevPorts.Core.ps1` 和 `TcpListeners.cs` 放在同一目录，在 Windows PowerShell 5.1 或 PowerShell 7 中运行以下命令。

```powershell
.\devports-gui.ps1
```

窗口默认每秒刷新一次 TCP 监听列表。取消勾选「自动刷新」可以暂停，也可以随时点击「刷新」。输入完整端口号（如 `3000`）或进程名的一部分（如 `node`）可以筛选，清空搜索框即可查看全部。

点击列表中的一行即可跟踪该端口的所有监听地址。也可以在搜索框输入端口号，再点击「跟踪端口」，提前观察一个还没有监听的端口。端口释放后，即使它从列表消失，窗口也会继续跟踪。

下方会记录观察到的开始监听、释放监听和进程变化，并显示时间、地址、进程名和 PID。每次切换端口会开始一段新记录，窗口保留当前端口最近 200 条。时间以发现变化的刷新时刻为准。

## 命令行版

```powershell
.\devports.ps1 list
.\devports.ps1 who 3000
.\devports.ps1 watch 3000
```

- `list` 列出本机正在监听的 TCP 端口，以及对应的监听地址、进程名和 PID。
- `who 3000` 列出 3000 端口上的所有监听项。能读取到进程的可执行文件路径时，也会一并显示。
- `watch 3000` 先显示当前状态，之后按监听地址报告变化。按 Ctrl+C 停止。默认每秒查询一次，可用 `-IntervalSeconds 2` 将间隔改为两秒。

```text
Watching TCP port 3000 every 1s. Press Ctrl+C to stop.
14:42:00  127.0.0.1:3000  node (PID 18420)
14:42:04  127.0.0.1:3000  node (PID 18420) -> no listener
14:42:08  127.0.0.1:3000  no listener -> node (PID 20936)
```

工具以只读方式查询本机的 TCP 表和进程信息，支持 IPv4 和 IPv6。两次查询之间发生又结束的变化可能会被漏掉。查询结果为空，表示查询当时未发现该端口上有 TCP 监听。

## 构建便携版

在 Windows x64 上，从项目目录运行 `./build-portable.ps1`。输出为 `dist/devports.exe`、`dist/devports-win-x64.zip` 和压缩包的 SHA-256 校验文件 `dist/devports-win-x64.zip.sha256`。压缩包内附 MIT 许可证。

[MIT 许可证](LICENSE)

# devports

English · [简体中文](README.zh-CN.md)

devports is a lightweight Windows tool for finding which process is listening on a TCP port and tracking when it starts, stops, or changes. Use it to troubleshoot `EADDRINUSE` and check what happens to a port when a local service restarts.

## Desktop app

Download `devports-win-x64.zip` from [GitHub Releases](https://github.com/shenxuekai/dev-ports/releases), extract it, and double-click `devports.exe`. The portable build targets Windows x64 and uses the built-in .NET Framework and Windows PowerShell 5.1. The v0.1.0 preview has a Chinese UI. Run the current source or build it locally to use the language selector.

The desktop app opens in English. Select **简体中文** (Simplified Chinese) from **Language** to switch the interface and existing port history. Search by an exact port number such as `3000` or part of a process name such as `node`. Clear the search to see all listeners. The list refreshes every second by default. Uncheck **Auto-refresh** to pause or click **Refresh** for a manual update.

Click a row to track the port across all its listening addresses. To track a port before anything is listening, enter its number and click **Track port**. Tracking continues when the port disappears from the list.

The history shows when a listener starts or stops, or when its owning process changes. Each entry includes the time, address, process name, and PID. The app keeps up to 200 entries for the selected port and starts a new history when you switch ports.

To run the desktop app from source, use the following command in the project directory with Windows PowerShell 5.1 or PowerShell 7 on Windows.

```powershell
.\devports-gui.ps1
```

## Command line

```powershell
.\devports.ps1 list
.\devports.ps1 who 3000
.\devports.ps1 watch 3000
```

- `list` shows local TCP listeners with their addresses, process names, and PIDs.
- `who 3000` shows every listener on port 3000 and the executable path when available.
- `watch 3000` shows the initial state and reports changes by listening address. Press Ctrl+C to stop. Use `-IntervalSeconds 2` to change the default one-second polling interval.

```text
Watching TCP port 3000 every 1s. Press Ctrl+C to stop.
14:42:00  127.0.0.1:3000  node (PID 18420)
14:42:04  127.0.0.1:3000  node (PID 18420) -> no listener
14:42:08  127.0.0.1:3000  no listener -> node (PID 20936)
```

devports reads the local TCP table and process information without modifying them. It supports IPv4 and IPv6. Timestamps show when a change was detected. Changes that start and end between polls may be missed.

## Build the portable app

On Windows x64, run `.\build-portable.ps1` from the project directory. The build writes `devports.exe`, `devports-win-x64.zip`, and `devports-win-x64.zip.sha256` to `dist`. The ZIP includes the MIT license.

[MIT License](LICENSE)

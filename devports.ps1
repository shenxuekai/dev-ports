#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('list', 'who', 'watch', 'help')]
    [string] $Command = 'help',

    [Parameter(Position = 1)]
    [string] $Port,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 1
)

function Watch-Listener {
    param([int] $PortNumber, [int] $Interval)

    $previous = Get-DevPortsSnapshot -Listeners @(Get-DevPortsListener -PortNumber $PortNumber)
    Write-Output "Watching TCP port $PortNumber every ${Interval}s. Press Ctrl+C to stop."
    if ($previous.Count -eq 0) {
        Write-Output "No TCP listeners on port $PortNumber."
    }
    foreach ($endpoint in ($previous.Keys | Sort-Object)) {
        Write-Output ('{0:HH:mm:ss}  {1}  {2}' -f (Get-Date), $endpoint, $previous[$endpoint].Description)
    }

    while ($true) {
        Start-Sleep -Seconds $Interval
        $current = Get-DevPortsSnapshot -Listeners @(Get-DevPortsListener -PortNumber $PortNumber)
        $timestamp = Get-Date
        foreach ($change in (Compare-DevPortsSnapshot -Previous $previous -Current $current)) {
            $from = if ($change.Before) { $change.Before.Description } else { 'no listener' }
            $to = if ($change.After) { $change.After.Description } else { 'no listener' }
            Write-Output ('{0:HH:mm:ss}  {1}  {2} -> {3}' -f $timestamp, $change.Endpoint, $from, $to)
        }
        $previous = $current
    }
}

try {
    $portNumber = 0
    if ($Command -in 'who', 'watch') {
        if (-not [int]::TryParse($Port, [Globalization.NumberStyles]::None, [Globalization.CultureInfo]::InvariantCulture, [ref] $portNumber) -or
            $portNumber -lt 1 -or $portNumber -gt 65535) {
            throw "'$Command' needs a TCP port from 1 to 65535."
        }
    } elseif ($PSBoundParameters.ContainsKey('Port')) {
        throw "'$Command' does not take a port."
    }

    if ($Command -ne 'watch' -and $PSBoundParameters.ContainsKey('IntervalSeconds')) {
        throw 'Only watch takes -IntervalSeconds.'
    }

    if ($Command -eq 'help') {
        Write-Output @'
devports v0.1.0 - Inspect local Windows TCP listeners.

  .\devports.ps1 list
  .\devports.ps1 who 3000
  .\devports.ps1 watch 3000 [-IntervalSeconds 1]
'@
        exit 0
    }

    . (Join-Path $PSScriptRoot 'DevPorts.Core.ps1')

    switch ($Command) {
        'list' {
            $listeners = @(Get-DevPortsListener | Sort-Object Port, Endpoint, PID)
            if ($listeners.Count -eq 0) {
                Write-Output 'No TCP listeners found.'
            } else {
                $listeners | Format-Table -Property Endpoint, Process, PID -AutoSize
            }
        }
        'who' {
            $listeners = @(Get-DevPortsListener -PortNumber $portNumber -IncludePath | Sort-Object Endpoint, PID)
            if ($listeners.Count -eq 0) {
                Write-Output "No TCP listeners on port $portNumber."
            }
            foreach ($listener in $listeners) {
                $path = if ($listener.Path) { $listener.Path } else { '<unavailable>' }
                Write-Output ('{0}  {1} (PID {2})' -f $listener.Endpoint, $listener.Process, $listener.PID)
                Write-Output "  Path: $path"
            }
        }
        'watch' {
            Watch-Listener -PortNumber $portNumber -Interval $IntervalSeconds
        }
    }
    exit 0
} catch {
    Write-Error -Message $_.Exception.Message -ErrorAction Continue
    exit 1
}

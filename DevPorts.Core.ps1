if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'devports requires Windows.'
}

if (-not ('DevPorts.TcpListeners' -as [type])) {
    Add-Type -Path (Join-Path $PSScriptRoot 'TcpListeners.cs') -ErrorAction Stop
}

function Get-DevPortsListener {
    param([int] $PortNumber, [switch] $IncludePath)

    $processes = @{}
    foreach ($row in [DevPorts.TcpListeners]::GetAll()) {
        if ($PortNumber -ne 0 -and $row.Port -ne $PortNumber) {
            continue
        }

        if (-not $processes.ContainsKey($row.ProcessId)) {
            $processes[$row.ProcessId] = Get-Process -Id $row.ProcessId -ErrorAction SilentlyContinue
        }
        $process = $processes[$row.ProcessId]
        $processName = if ($process) { $process.ProcessName } else { '<unavailable>' }
        $processPath = if ($IncludePath -and $process) { $process.Path }
        $address = if ($row.Address.Contains(':')) { "[$($row.Address)]" } else { $row.Address }

        [pscustomobject]@{
            Endpoint = '{0}:{1}' -f $address, $row.Port
            Address  = $row.Address
            Port     = $row.Port
            Process  = $processName
            PID      = $row.ProcessId
            Path     = $processPath
        }
    }
}

function Get-DevPortsSnapshot {
    param([object[]] $Listeners)

    $snapshot = @{}
    foreach ($group in ($Listeners | Group-Object Endpoint)) {
        $owners = @($group.Group | Sort-Object PID -Unique)
        $snapshot[$group.Name] = @{
            OwnerIds    = $owners.PID -join ','
            Description = ($owners | ForEach-Object { '{0} (PID {1})' -f $_.Process, $_.PID }) -join ', '
        }
    }
    return $snapshot
}

function Compare-DevPortsSnapshot {
    param([hashtable] $Previous, [hashtable] $Current)

    $endpoints = @($Previous.Keys) + @($Current.Keys) | Sort-Object -Unique
    foreach ($endpoint in $endpoints) {
        $before = $Previous[$endpoint]
        $after = $Current[$endpoint]
        if ($before -and $after -and $before.OwnerIds -eq $after.OwnerIds) {
            continue
        }

        [pscustomobject]@{
            Endpoint = $endpoint
            Before   = $before
            After    = $after
        }
    }
}

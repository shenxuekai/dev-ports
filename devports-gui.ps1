#requires -Version 5.1
using namespace System.Drawing
using namespace System.Windows.Forms

$ErrorActionPreference = 'Stop'
if ($PSScriptRoot) {
    . (Join-Path $PSScriptRoot 'DevPorts.Core.ps1')
}

if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    throw '请使用 powershell.exe -STA -File .\devports-gui.ps1 或 pwsh -STA -File .\devports-gui.ps1 启动。'
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Application]::EnableVisualStyles()
$ink = [ColorTranslator]::FromHtml('#17263D')
$muted = [ColorTranslator]::FromHtml('#50627B')
$background = [ColorTranslator]::FromHtml('#F1F5FA')
$accent = [ColorTranslator]::FromHtml('#1D55C6')

$form = [Form]::new()
$form.Text = 'devports'
$form.StartPosition = 'CenterScreen'
$form.AutoScaleDimensions = [SizeF]::new(96, 96)
$form.AutoScaleMode = 'Dpi'
$form.ClientSize = [Size]::new(840, 690)
$form.MinimumSize = [Size]::new(590, 490)
$form.BackColor = $background
$form.ForeColor = $ink
$form.Font = [Font]::new('Microsoft YaHei UI', 10)

$layout = [TableLayoutPanel]::new()
$layout.Dock = 'Fill'
$layout.Padding = [Padding]::new(24, 16, 24, 12)
$layout.ColumnCount = 1
$layout.RowCount = 6
[void] $layout.ColumnStyles.Add([ColumnStyle]::new('Percent', 100))
[void] $layout.RowStyles.Add([RowStyle]::new('Absolute', 58))
[void] $layout.RowStyles.Add([RowStyle]::new('Absolute', 49))
[void] $layout.RowStyles.Add([RowStyle]::new('Percent', 64))
[void] $layout.RowStyles.Add([RowStyle]::new('Absolute', 32))
[void] $layout.RowStyles.Add([RowStyle]::new('Absolute', 40))
[void] $layout.RowStyles.Add([RowStyle]::new('Percent', 36))
$form.Controls.Add($layout)

$title = [Label]::new()
$title.Text = 'TCP 监听端口'
$title.Dock = 'Fill'
$title.Margin = [Padding]::new(0)
$title.TextAlign = 'MiddleLeft'
$title.Font = [Font]::new($form.Font.FontFamily, 22, [FontStyle]::Bold)
$layout.Controls.Add($title, 0, 0)

$toolbar = [TableLayoutPanel]::new()
$toolbar.Dock = 'Fill'
$toolbar.Margin = [Padding]::new(0, 0, 0, 12)
$toolbar.RowCount = 1
$toolbar.ColumnCount = 4
[void] $toolbar.ColumnStyles.Add([ColumnStyle]::new('Absolute', 104))
[void] $toolbar.ColumnStyles.Add([ColumnStyle]::new('Percent', 100))
[void] $toolbar.ColumnStyles.Add([ColumnStyle]::new('Absolute', 146))
[void] $toolbar.ColumnStyles.Add([ColumnStyle]::new('Absolute', 90))
$layout.Controls.Add($toolbar, 0, 1)

$searchLabel = [Label]::new()
$searchLabel.Text = '端口或进程名'
$searchLabel.Dock = 'Fill'
$searchLabel.Margin = [Padding]::new(0)
$searchLabel.TextAlign = 'MiddleLeft'
$toolbar.Controls.Add($searchLabel, 0, 0)

$search = [TextBox]::new()
$search.Name = 'ListenerSearch'
$search.AccessibleName = '搜索端口或进程名'
$search.Anchor = 'Left, Right'
$search.Margin = [Padding]::new(0, 0, 12, 0)
$search.Font = [Font]::new($form.Font.FontFamily, 11)
$toolbar.Controls.Add($search, 1, 0)

$automatic = [CheckBox]::new()
$automatic.Name = 'AutoRefresh'
$automatic.Text = '自动刷新（1 秒）'
$automatic.Checked = $true
$automatic.Dock = 'Fill'
$automatic.Margin = [Padding]::new(0)
$toolbar.Controls.Add($automatic, 2, 0)

$refresh = [Button]::new()
$refresh.Name = 'RefreshListeners'
$refresh.Text = '刷新'
$refresh.Dock = 'Fill'
$refresh.Margin = [Padding]::new(0)
$refresh.FlatStyle = 'Flat'
$refresh.FlatAppearance.BorderSize = 0
$refresh.UseVisualStyleBackColor = $false
$refresh.BackColor = $accent
$refresh.ForeColor = [Color]::White
$toolbar.Controls.Add($refresh, 3, 0)

$grid = [DataGridView]::new()
$grid.Name = 'ListenerList'
$grid.AccessibleName = 'TCP 监听列表'
$grid.Dock = 'Fill'
$grid.Margin = [Padding]::new(0)
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.AllowUserToResizeRows = $false
$grid.RowHeadersVisible = $false
$grid.AutoGenerateColumns = $false
$grid.AutoSizeColumnsMode = 'Fill'
$grid.SelectionMode = 'FullRowSelect'
$grid.MultiSelect = $false
$grid.BackgroundColor = [Color]::White
$grid.GridColor = [ColorTranslator]::FromHtml('#DFE7F1')
$grid.CellBorderStyle = 'SingleHorizontal'
$grid.EnableHeadersVisualStyles = $false
$grid.ColumnHeadersHeight = 38
$grid.ColumnHeadersHeightSizeMode = 'DisableResizing'
$grid.ColumnHeadersDefaultCellStyle.BackColor = [ColorTranslator]::FromHtml('#E7EEF8')
$grid.ColumnHeadersDefaultCellStyle.ForeColor = $ink
$grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = $grid.ColumnHeadersDefaultCellStyle.BackColor
$grid.ColumnHeadersDefaultCellStyle.Padding = [Padding]::new(8, 0, 4, 0)
$grid.RowTemplate.Height = 34
$grid.DefaultCellStyle.ForeColor = $ink
$grid.DefaultCellStyle.SelectionBackColor = [ColorTranslator]::FromHtml('#DCEBFF')
$grid.DefaultCellStyle.SelectionForeColor = $ink
$grid.DefaultCellStyle.Padding = [Padding]::new(8, 0, 4, 0)
$grid.AlternatingRowsDefaultCellStyle.BackColor = [ColorTranslator]::FromHtml('#F7F9FD')
$layout.Controls.Add($grid, 0, 2)

foreach ($spec in @(
    @{ Name = 'Port'; Header = '端口'; Width = 15; ValueType = [int] }
    @{ Name = 'Address'; Header = '监听地址'; Width = 38; ValueType = [string] }
    @{ Name = 'Process'; Header = '进程名'; Width = 32; ValueType = [string] }
    @{ Name = 'PID'; Header = 'PID'; Width = 15; ValueType = [uint32] }
)) {
    $column = [DataGridViewTextBoxColumn]::new()
    $column.Name = $spec.Name
    $column.HeaderText = $spec.Header
    $column.FillWeight = $spec.Width
    $column.ValueType = $spec.ValueType
    $column.SortMode = 'Automatic'
    [void] $grid.Columns.Add($column)
}

$status = [Label]::new()
$status.Name = 'ListenerStatus'
$status.AccessibleName = '列表状态'
$status.Dock = 'Fill'
$status.Margin = [Padding]::new(0)
$status.TextAlign = 'MiddleLeft'
$status.ForeColor = $muted
$status.Text = '正在读取 TCP 监听端口…'
$layout.Controls.Add($status, 0, 3)

$historyBar = [TableLayoutPanel]::new()
$historyBar.Dock = 'Fill'
$historyBar.Margin = [Padding]::new(0, 0, 0, 6)
$historyBar.RowCount = 1
$historyBar.ColumnCount = 3
[void] $historyBar.ColumnStyles.Add([ColumnStyle]::new('Absolute', 126))
[void] $historyBar.ColumnStyles.Add([ColumnStyle]::new('Percent', 100))
[void] $historyBar.ColumnStyles.Add([ColumnStyle]::new('Absolute', 102))
$layout.Controls.Add($historyBar, 0, 4)

$historyTitle = [Label]::new()
$historyTitle.Text = '端口变化记录'
$historyTitle.Font = [Font]::new($form.Font.FontFamily, 12, [FontStyle]::Bold)
$historyTitle.Dock = 'Fill'
$historyTitle.Margin = [Padding]::new(0)
$historyTitle.TextAlign = 'MiddleLeft'
$historyBar.Controls.Add($historyTitle, 0, 0)

$tracking = [Label]::new()
$tracking.Name = 'TrackedPortStatus'
$tracking.Text = '选择一行，或输入端口号开始跟踪'
$tracking.Dock = 'Fill'
$tracking.Margin = [Padding]::new(0)
$tracking.TextAlign = 'MiddleLeft'
$tracking.ForeColor = $muted
$tracking.AutoEllipsis = $true
$historyBar.Controls.Add($tracking, 1, 0)

$track = [Button]::new()
$track.Name = 'TrackSearchPort'
$track.Text = '跟踪端口'
$track.AccessibleDescription = '跟踪搜索框内的端口号'
$track.Enabled = $false
$track.Dock = 'Fill'
$track.Margin = [Padding]::new(0)
$historyBar.Controls.Add($track, 2, 0)

$history = [RichTextBox]::new()
$history.Name = 'PortHistory'
$history.AccessibleName = '端口变化记录'
$history.Dock = 'Fill'
$history.Margin = [Padding]::new(0)
$history.ReadOnly = $true
$history.DetectUrls = $false
$history.BackColor = [Color]::White
$history.ScrollBars = 'Vertical'
$layout.Controls.Add($history, 0, 5)

$state = @{
    Listeners = @()
    UpdatedAt = $null
    RefreshFailed = $false
    SearchPort = 0
    TrackedPort = 0
    TrackedSnapshot = $null
    History = [Collections.Generic.Queue[string]]::new()
    RenderingList = $false
    VisibleSignature = $null
}

function Show-ListenerList {
    $query = $search.Text.Trim()
    $visible = $state.Listeners
    $state.SearchPort = 0
    if ($query -match '^[0-9]+$') {
        $portNumber = 0
        $visible = @()
        if ([int]::TryParse($query, [ref] $portNumber) -and $portNumber -ge 1 -and $portNumber -le 65535) {
            $state.SearchPort = $portNumber
            $visible = @($state.Listeners | Where-Object { $_.Port -eq $portNumber })
        }
    } elseif ($query) {
        $visible = @($state.Listeners | Where-Object {
            $_.Process.IndexOf($query, [StringComparison]::OrdinalIgnoreCase) -ge 0
        })
    }
    $track.Enabled = $state.SearchPort -gt 0

    $signature = ($visible | ForEach-Object { '{0}|{1}|{2}' -f $_.Endpoint, $_.PID, $_.Process }) -join [Environment]::NewLine
    if ($state.VisibleSignature -cne $signature) {
        $sortColumn = $grid.SortedColumn
        $direction = if ($grid.SortOrder -eq 'Descending') { 'Descending' } else { 'Ascending' }
        $selectedAddress = $null
        $selectedOwner = $null
        if ($grid.SelectedRows.Count) {
            $selectedAddress = $grid.SelectedRows[0].Cells['Address'].Value
            $selectedOwner = $grid.SelectedRows[0].Cells['PID'].Value
        }
        $state.RenderingList = $true
        $grid.SuspendLayout()
        try {
            $grid.Rows.Clear()
            foreach ($listener in $visible) {
                $name = if ($listener.Process -eq '<unavailable>') { '不可用' } else { $listener.Process }
                [void] $grid.Rows.Add([object[]] @($listener.Port, $listener.Address, $name, $listener.PID))
            }
            if ($sortColumn -and $grid.RowCount -gt 0) {
                $grid.Sort($sortColumn, $direction)
            }
            $grid.ClearSelection()
            if ($state.TrackedPort) {
                $rows = @($grid.Rows | Where-Object { $_.Cells['Port'].Value -eq $state.TrackedPort })
                if ($rows.Count) {
                    $row = $rows[0]
                    if ($selectedAddress) {
                        $sameAddress = @($rows | Where-Object { $_.Cells['Address'].Value -eq $selectedAddress })
                        if ($sameAddress.Count) {
                            $row = $sameAddress[0]
                            $sameOwner = $sameAddress | Where-Object { $_.Cells['PID'].Value -eq $selectedOwner } | Select-Object -First 1
                            if ($sameOwner) { $row = $sameOwner }
                        }
                    }
                    $grid.CurrentCell = $row.Cells[0]
                    $row.Selected = $true
                }
            }
            $state.VisibleSignature = $signature
        } finally {
            $grid.ResumeLayout()
            $state.RenderingList = $false
        }
    }

    $status.Text = if ($state.RefreshFailed) {
        if ($state.UpdatedAt) { '刷新失败，表格显示上次结果。' } else { '读取失败，请点击刷新重试。' }
    } elseif ($state.Listeners.Count -eq 0) {
        '本机没有 TCP 监听项。'
    } elseif ($grid.RowCount -eq 0) {
        '没有匹配的端口或进程。'
    } else {
        '显示 {0} / {1} 项   ·   更新于 {2:HH:mm:ss}' -f $grid.RowCount, $state.Listeners.Count, $state.UpdatedAt
    }
}

function Update-PortHistory {
    if (-not $state.TrackedPort) {
        return
    }

    $listeners = @($state.Listeners | Where-Object { $_.Port -eq $state.TrackedPort })
    $current = Get-DevPortsSnapshot -Listeners $listeners
    $tracking.Text = if ($current.Count) {
        '端口 {0} · 监听中（{1} 个地址）' -f $state.TrackedPort, $current.Count
    } else {
        '端口 {0} · 当前无监听' -f $state.TrackedPort
    }

    $previous = $state.TrackedSnapshot
    $entries = if ($null -eq $previous) {
        if ($current.Count) {
            foreach ($endpoint in ($current.Keys | Sort-Object)) {
                '初始监听   {0}   {1}' -f $endpoint, $current[$endpoint].Description
            }
        } else {
            '初始状态   当前无监听'
        }
    } else {
        foreach ($change in (Compare-DevPortsSnapshot -Previous $previous -Current $current)) {
            if (-not $change.Before) {
                '开始监听   {0}   {1}' -f $change.Endpoint, $change.After.Description
            } elseif (-not $change.After) {
                '释放监听   {0}   {1}' -f $change.Endpoint, $change.Before.Description
            } else {
                '进程变化   {0}   {1} → {2}' -f $change.Endpoint, $change.Before.Description, $change.After.Description
            }
        }
    }
    $state.TrackedSnapshot = $current
    if ($entries) {
        foreach ($entry in $entries) {
            $state.History.Enqueue(('{0:MM-dd HH:mm:ss}   {1}' -f $state.UpdatedAt, $entry.Replace('<unavailable>', '不可用')))
            if ($state.History.Count -gt 200) {
                [void] $state.History.Dequeue()
            }
        }
        $history.Lines = $state.History.ToArray()
        $history.SelectionStart = $history.TextLength
        $history.ScrollToCaret()
    }
}

function Set-TrackedPort {
    param([int] $PortNumber)

    if ($state.TrackedPort -eq $PortNumber) {
        return
    }

    $state.TrackedPort = $PortNumber
    $state.TrackedSnapshot = $null
    $state.History.Clear()
    $history.Clear()
    if ($state.UpdatedAt -and -not $state.RefreshFailed) {
        Update-PortHistory
    } else {
        $tracking.Text = '端口 {0} · 等待刷新' -f $PortNumber
    }
}

function Update-ListenerList {
    try {
        $state.Listeners = @(Get-DevPortsListener | Sort-Object Port, Address, PID)
    } catch {
        $state.RefreshFailed = $true
        Write-Warning $_.Exception.Message
        Show-ListenerList
        return
    }
    $state.UpdatedAt = Get-Date
    $state.RefreshFailed = $false
    Update-PortHistory
    Show-ListenerList
}

$timer = [System.Windows.Forms.Timer]::new()
$timer.Interval = 1000
$timer.Add_Tick({ Update-ListenerList })
$automatic.Add_CheckedChanged({ $timer.Enabled = $automatic.Checked })
$search.Add_TextChanged({ Show-ListenerList })
$refresh.Add_Click({ Update-ListenerList })
$track.Add_Click({
    Set-TrackedPort -PortNumber $state.SearchPort
    $state.VisibleSignature = $null
    Show-ListenerList
})
$grid.Add_SelectionChanged({
    if (-not $state.RenderingList -and $grid.SelectedRows.Count) {
        $selectedPort = $grid.SelectedRows[0].Cells['Port'].Value
        if ($selectedPort) { Set-TrackedPort -PortNumber $selectedPort }
    }
})
$form.Add_Shown({
    Update-ListenerList
    [void] $search.Focus()
    $timer.Enabled = $automatic.Checked
})

try {
    [void] $form.ShowDialog()
} finally {
    $timer.Stop()
    $timer.Dispose()
    $form.Dispose()
}

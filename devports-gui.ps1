#requires -Version 5.1
using namespace System.Drawing
using namespace System.Windows.Forms

$ErrorActionPreference = 'Stop'
if ($PSScriptRoot) {
    . (Join-Path $PSScriptRoot 'DevPorts.Core.ps1')
}

if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    throw 'Start devports with powershell.exe -STA -File .\devports-gui.ps1 or pwsh -STA -File .\devports-gui.ps1.'
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Application]::EnableVisualStyles()
$ink = [ColorTranslator]::FromHtml('#17263D')
$muted = [ColorTranslator]::FromHtml('#50627B')
$background = [ColorTranslator]::FromHtml('#F1F5FA')
$accent = [ColorTranslator]::FromHtml('#1D55C6')

$translations = @{
    en = @{
        Title = 'TCP listeners'
        Language = 'Language'
        Search = 'Port or process'
        AutoRefresh = 'Auto-refresh (1 s)'
        Refresh = 'Refresh'
        ListenerList = 'TCP listener list'
        Port = 'Port'
        Address = 'Listening address'
        Process = 'Process'
        Status = 'List status'
        Loading = 'Reading TCP listeners…'
        RefreshFailed = 'Refresh failed. Showing the last result.'
        ReadFailed = 'Could not read TCP listeners. Click Refresh to retry.'
        NoListeners = 'No local TCP listeners.'
        NoMatches = 'No matching ports or processes.'
        Results = 'Showing {0} / {1}   ·   Updated at {2:HH:mm:ss}'
        History = 'Port history'
        ChoosePort = 'Select a row or enter a port to track.'
        TrackPort = 'Track port'
        TrackDescription = 'Track the port number in the search field.'
        Unavailable = 'Unavailable'
        Waiting = 'Port {0} · Waiting for refresh'
        Listening = 'Port {0} · Listening on {1}'
        SingleAddress = '1 address'
        MultipleAddresses = '{0} addresses'
        Idle = 'Port {0} · No listener'
        InitialIdle = 'Initial state   No listener'
        InitialListening = 'Initially listening   {0}   {1}'
        Started = 'Started listening   {0}   {1}'
        Released = 'Listener stopped   {0}   {1}'
        Changed = 'Process changed   {0}   {1} → {2}'
    }
    'zh-CN' = @{
        Title = 'TCP 监听端口'
        Language = '语言'
        Search = '端口或进程名'
        AutoRefresh = '自动刷新（1 秒）'
        Refresh = '刷新'
        ListenerList = 'TCP 监听列表'
        Port = '端口'
        Address = '监听地址'
        Process = '进程名'
        Status = '列表状态'
        Loading = '正在读取 TCP 监听端口…'
        RefreshFailed = '刷新失败，表格显示上次结果。'
        ReadFailed = '读取失败，请点击刷新重试。'
        NoListeners = '本机没有 TCP 监听项。'
        NoMatches = '没有匹配的端口或进程。'
        Results = '显示 {0} / {1} 项   ·   更新于 {2:HH:mm:ss}'
        History = '端口变化记录'
        ChoosePort = '选择一行，或输入端口号开始跟踪'
        TrackPort = '跟踪端口'
        TrackDescription = '跟踪搜索框内的端口号'
        Unavailable = '不可用'
        Waiting = '端口 {0} · 等待刷新'
        Listening = '端口 {0} · 监听中（{1}）'
        SingleAddress = '1 个地址'
        MultipleAddresses = '{0} 个地址'
        Idle = '端口 {0} · 当前无监听'
        InitialIdle = '初始状态   当前无监听'
        InitialListening = '初始监听   {0}   {1}'
        Started = '开始监听   {0}   {1}'
        Released = '释放监听   {0}   {1}'
        Changed = '进程变化   {0}   {1} → {2}'
    }
}

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

$header = [TableLayoutPanel]::new()
$header.Dock = 'Fill'
$header.Margin = [Padding]::new(0)
$header.RowCount = 1
$header.ColumnCount = 3
[void] $header.ColumnStyles.Add([ColumnStyle]::new('Percent', 100))
[void] $header.ColumnStyles.Add([ColumnStyle]::new('Absolute', 92))
[void] $header.ColumnStyles.Add([ColumnStyle]::new('Absolute', 116))
$layout.Controls.Add($header, 0, 0)

$title = [Label]::new()
$title.Dock = 'Fill'
$title.Margin = [Padding]::new(0)
$title.TextAlign = 'MiddleLeft'
$title.Font = [Font]::new($form.Font.FontFamily, 22, [FontStyle]::Bold)
$header.Controls.Add($title, 0, 0)

$languageLabel = [Label]::new()
$languageLabel.Dock = 'Fill'
$languageLabel.Margin = [Padding]::new(0, 0, 8, 0)
$languageLabel.TextAlign = 'MiddleRight'
$header.Controls.Add($languageLabel, 1, 0)

$language = [ComboBox]::new()
$language.Name = 'DisplayLanguage'
$language.DropDownStyle = 'DropDownList'
$language.Anchor = 'Left, Right'
$language.Margin = [Padding]::new(0)
$language.Items.AddRange([object[]] @('English', '简体中文'))
$language.SelectedIndex = 0
$header.Controls.Add($language, 2, 0)

$toolbar = [TableLayoutPanel]::new()
$toolbar.Dock = 'Fill'
$toolbar.Margin = [Padding]::new(0, 0, 0, 12)
$toolbar.RowCount = 1
$toolbar.ColumnCount = 4
[void] $toolbar.ColumnStyles.Add([ColumnStyle]::new('Absolute', 116))
[void] $toolbar.ColumnStyles.Add([ColumnStyle]::new('Percent', 100))
[void] $toolbar.ColumnStyles.Add([ColumnStyle]::new('Absolute', 146))
[void] $toolbar.ColumnStyles.Add([ColumnStyle]::new('Absolute', 90))
$layout.Controls.Add($toolbar, 0, 1)

$searchLabel = [Label]::new()
$searchLabel.Dock = 'Fill'
$searchLabel.Margin = [Padding]::new(0)
$searchLabel.TextAlign = 'MiddleLeft'
$toolbar.Controls.Add($searchLabel, 0, 0)

$search = [TextBox]::new()
$search.Name = 'ListenerSearch'
$search.Anchor = 'Left, Right'
$search.Margin = [Padding]::new(0, 0, 12, 0)
$search.Font = [Font]::new($form.Font.FontFamily, 11)
$toolbar.Controls.Add($search, 1, 0)

$automatic = [CheckBox]::new()
$automatic.Name = 'AutoRefresh'
$automatic.Checked = $true
$automatic.Dock = 'Fill'
$automatic.Margin = [Padding]::new(0)
$toolbar.Controls.Add($automatic, 2, 0)

$refresh = [Button]::new()
$refresh.Name = 'RefreshListeners'
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
    @{ Name = 'Port'; Width = 15; ValueType = [int] }
    @{ Name = 'Address'; Width = 38; ValueType = [string] }
    @{ Name = 'Process'; Width = 32; ValueType = [string] }
    @{ Name = 'PID'; Width = 15; ValueType = [uint32] }
)) {
    $column = [DataGridViewTextBoxColumn]::new()
    $column.Name = $spec.Name
    $column.HeaderText = $spec.Name
    $column.FillWeight = $spec.Width
    $column.ValueType = $spec.ValueType
    $column.SortMode = 'Automatic'
    [void] $grid.Columns.Add($column)
}

$status = [Label]::new()
$status.Name = 'ListenerStatus'
$status.Dock = 'Fill'
$status.Margin = [Padding]::new(0)
$status.TextAlign = 'MiddleLeft'
$status.ForeColor = $muted
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
$historyTitle.Font = [Font]::new($form.Font.FontFamily, 12, [FontStyle]::Bold)
$historyTitle.Dock = 'Fill'
$historyTitle.Margin = [Padding]::new(0)
$historyTitle.TextAlign = 'MiddleLeft'
$historyBar.Controls.Add($historyTitle, 0, 0)

$tracking = [Label]::new()
$tracking.Name = 'TrackedPortStatus'
$tracking.Dock = 'Fill'
$tracking.Margin = [Padding]::new(0)
$tracking.TextAlign = 'MiddleLeft'
$tracking.ForeColor = $muted
$tracking.AutoEllipsis = $true
$historyBar.Controls.Add($tracking, 1, 0)

$track = [Button]::new()
$track.Name = 'TrackSearchPort'
$track.Enabled = $false
$track.Dock = 'Fill'
$track.Margin = [Padding]::new(0)
$historyBar.Controls.Add($track, 2, 0)

$history = [RichTextBox]::new()
$history.Name = 'PortHistory'
$history.Dock = 'Fill'
$history.Margin = [Padding]::new(0)
$history.ReadOnly = $true
$history.DetectUrls = $false
$history.BackColor = [Color]::White
$history.ScrollBars = 'Vertical'
$layout.Controls.Add($history, 0, 5)

$state = @{
    Text = $translations.en
    Listeners = @()
    UpdatedAt = $null
    RefreshFailed = $false
    SearchPort = 0
    TrackedPort = 0
    TrackedSnapshot = $null
    History = [Collections.Generic.Queue[hashtable]]::new()
    RenderingList = $false
    VisibleSignature = $null
}

function Show-ListenerList {
    $text = $state.Text
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
                $name = if ($listener.Process -eq '<unavailable>') { $text.Unavailable } else { $listener.Process }
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
        if ($state.UpdatedAt) { $text.RefreshFailed } else { $text.ReadFailed }
    } elseif (-not $state.UpdatedAt) {
        $text.Loading
    } elseif ($state.Listeners.Count -eq 0) {
        $text.NoListeners
    } elseif ($grid.RowCount -eq 0) {
        $text.NoMatches
    } else {
        $text.Results -f $grid.RowCount, $state.Listeners.Count, $state.UpdatedAt
    }
}

function Show-TrackingStatus {
    $text = $state.Text
    $tracking.Text = if (-not $state.TrackedPort) {
        $text.ChoosePort
    } elseif ($null -eq $state.TrackedSnapshot) {
        $text.Waiting -f $state.TrackedPort
    } elseif ($state.TrackedSnapshot.Count) {
        $count = $state.TrackedSnapshot.Count
        $addresses = if ($count -eq 1) { $text.SingleAddress } else { $text.MultipleAddresses -f $count }
        $text.Listening -f $state.TrackedPort, $addresses
    } else {
        $text.Idle -f $state.TrackedPort
    }
}

function Show-PortHistory {
    $text = $state.Text
    $history.Lines = [string[]] @(
        foreach ($entry in $state.History) {
            $message = $text[$entry.Key] -f $entry.Arguments
            '{0:MM-dd HH:mm:ss}   {1}' -f $entry.At, $message.Replace('<unavailable>', $text.Unavailable)
        }
    )
    $history.SelectionStart = $history.TextLength
    $history.ScrollToCaret()
}

function Update-PortHistory {
    if (-not $state.TrackedPort) {
        return
    }

    $listeners = @($state.Listeners | Where-Object { $_.Port -eq $state.TrackedPort })
    $current = Get-DevPortsSnapshot -Listeners $listeners
    $previous = $state.TrackedSnapshot
    $entries = @(
        $startKey = 'Started'
        if ($null -eq $previous) {
            $startKey = 'InitialListening'
            $previous = @{}
            if (-not $current.Count) {
                @{ Key = 'InitialIdle'; Arguments = @() }
            }
        }
        foreach ($change in (Compare-DevPortsSnapshot -Previous $previous -Current $current)) {
            if (-not $change.Before) {
                @{ Key = $startKey; Arguments = @($change.Endpoint, $change.After.Description) }
            } elseif (-not $change.After) {
                @{ Key = 'Released'; Arguments = @($change.Endpoint, $change.Before.Description) }
            } else {
                @{ Key = 'Changed'; Arguments = @($change.Endpoint, $change.Before.Description, $change.After.Description) }
            }
        }
    )
    $state.TrackedSnapshot = $current
    Show-TrackingStatus
    if ($entries.Count) {
        foreach ($entry in $entries) {
            $entry.At = $state.UpdatedAt
            $state.History.Enqueue($entry)
            if ($state.History.Count -gt 200) {
                [void] $state.History.Dequeue()
            }
        }
        Show-PortHistory
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
        Show-TrackingStatus
    }
}

function Set-DisplayLanguage {
    $text = if ($language.SelectedIndex -eq 1) { $translations['zh-CN'] } else { $translations.en }
    $state.Text = $text
    $title.Text = $text.Title
    $languageLabel.Text = $text.Language
    $language.AccessibleName = $text.Language
    $searchLabel.Text = $text.Search
    $search.AccessibleName = $text.Search
    $automatic.Text = $text.AutoRefresh
    $refresh.Text = $text.Refresh
    $grid.AccessibleName = $text.ListenerList
    $grid.Columns['Port'].HeaderText = $text.Port
    $grid.Columns['Address'].HeaderText = $text.Address
    $grid.Columns['Process'].HeaderText = $text.Process
    $status.AccessibleName = $text.Status
    $historyTitle.Text = $text.History
    $history.AccessibleName = $text.History
    $track.Text = $text.TrackPort
    $track.AccessibleDescription = $text.TrackDescription
    $state.VisibleSignature = $null
    Show-ListenerList
    Show-TrackingStatus
    Show-PortHistory
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
$language.Add_SelectedIndexChanged({ Set-DisplayLanguage })
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
    Set-DisplayLanguage
    [void] $form.ShowDialog()
} finally {
    $timer.Stop()
    $timer.Dispose()
    $form.Dispose()
}

#requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$framework = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
$compiler = Join-Path $framework 'csc.exe'
$automationGac = Join-Path $env:WINDIR 'Microsoft.NET\assembly\GAC_MSIL\System.Management.Automation'

if (-not (Test-Path -LiteralPath $compiler -PathType Leaf) -or
    -not (Test-Path -LiteralPath $automationGac -PathType Container)) {
    throw 'Building devports requires 64-bit Windows with .NET Framework and Windows PowerShell 5.1.'
}
$automation = Get-ChildItem -LiteralPath $automationGac -Filter System.Management.Automation.dll -File -Recurse |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $automation) {
    throw 'Could not locate the Windows PowerShell 5.1 automation assembly.'
}

$dist = Join-Path $root 'dist'
$null = New-Item -ItemType Directory -Path $dist -Force
$exe = Join-Path $dist 'devports.exe'
$zip = Join-Path $dist 'devports-win-x64.zip'
$compilerArgs = @(
    '/nologo'
    '/target:winexe'
    '/platform:x64'
    '/optimize+'
    '/codepage:65001'
    "/reference:$automation"
    '/reference:System.Windows.Forms.dll'
    ('/resource:{0},DevPorts.Core.ps1' -f (Join-Path $root 'DevPorts.Core.ps1'))
    ('/resource:{0},devports-gui.ps1' -f (Join-Path $root 'devports-gui.ps1'))
    "/out:$exe"
    (Join-Path $root 'DevPorts.Launcher.cs')
    (Join-Path $root 'TcpListeners.cs')
)
& $compiler @compilerArgs
if ($LASTEXITCODE -ne 0) {
    throw "The compiler exited with code $LASTEXITCODE."
}

Compress-Archive -LiteralPath $exe, (Join-Path $root 'LICENSE') -DestinationPath $zip -Force
$checksum = "$zip.sha256"
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
'{0}  {1}' -f $hash, (Split-Path -Leaf $zip) | Set-Content -LiteralPath $checksum -Encoding Ascii
Write-Output $exe, $zip, $checksum

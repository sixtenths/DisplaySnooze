$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $projectDir 'Program.cs'
$output = Join-Path $projectDir 'DisplaySnooze.exe'
$icon = Join-Path $projectDir 'assets\DisplaySnooze.ico'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'

if (-not (Test-Path -LiteralPath $compiler)) {
    $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}

if (-not (Test-Path -LiteralPath $compiler)) {
    throw 'Could not find the .NET Framework C# compiler.'
}

if (-not (Test-Path -LiteralPath $icon)) {
    throw "Could not find the Windows icon at $icon. Run tools\New-DisplaySnoozeIcon.ps1 to regenerate it."
}

& $compiler /nologo /optimize+ /target:winexe /platform:anycpu /win32icon:$icon /out:$output $source

Write-Host "Built $output"

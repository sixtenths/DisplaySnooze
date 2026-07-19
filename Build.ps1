$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$normalSource = Join-Path $projectDir 'Program.cs'
$ddcciSource = Join-Path $projectDir 'ProgramDdcci.cs'
$coreSource = Join-Path $projectDir 'DisplaySnoozeCore.cs'
$normalOutput = Join-Path $projectDir 'DisplaySnooze.exe'
$ddcciOutput = Join-Path $projectDir 'DisplaySnoozeDdcci.exe'
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

& $compiler /nologo /optimize+ /target:winexe /platform:anycpu /win32icon:$icon /out:$normalOutput $normalSource $coreSource
& $compiler /nologo /optimize+ /target:winexe /platform:anycpu /win32icon:$icon /out:$ddcciOutput $ddcciSource $coreSource

Write-Host "Built $normalOutput"
Write-Host "Built $ddcciOutput"

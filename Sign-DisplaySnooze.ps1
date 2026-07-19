$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exes = @(
    (Join-Path $projectDir 'DisplaySnooze.exe'),
    (Join-Path $projectDir 'DisplaySnoozeDdcci.exe')
)
$certPath = Join-Path $projectDir 'DisplaySnoozeLocalCodeSigning.cer'
$subject = 'CN=Zac DisplaySnooze Local Code Signing'

foreach ($exe in $exes) {
    if (-not (Test-Path -LiteralPath $exe)) {
        throw "Build DisplaySnooze first: $exe"
    }
}

$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert |
    Where-Object { $_.Subject -eq $subject -and $_.NotAfter -gt (Get-Date).AddDays(30) } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if (-not $cert) {
    $cert = New-SelfSignedCertificate `
        -Type CodeSigningCert `
        -Subject $subject `
        -FriendlyName 'DisplaySnooze Local Code Signing' `
        -CertStoreLocation Cert:\CurrentUser\My `
        -KeyUsage DigitalSignature `
        -HashAlgorithm SHA256 `
        -NotAfter (Get-Date).AddYears(5)
}

foreach ($exe in $exes) {
    Set-AuthenticodeSignature -FilePath $exe -Certificate $cert -HashAlgorithm SHA256
    Write-Host "Signed $exe"
}

Export-Certificate -Cert $cert -FilePath $certPath | Out-Null

Write-Host "Exported $certPath"

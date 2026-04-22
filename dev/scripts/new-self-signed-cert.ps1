#!/usr/bin/env pwsh
# Generate a self-signed code-signing certificate for CI release signing.
# Run ONCE (or when the cert expires). Produces:
#   - dev-cert.pfx  (private, load into CODE_SIGN_CERT_PFX_BASE64 secret)
#   - dev-cert.cer  (public, distribute via GitHub Release for end-user trust)
#
# Requires Windows OR PowerShell 7+ on macOS with `pwsh`.
param(
    [Parameter(Mandatory = $true)]
    [string]$Password,

    [string]$Subject = "CN=powerbi-openehr-aql Dev Cert",
    [string]$OutputDir = "."
)

$ErrorActionPreference = 'Stop'

if (-not $IsWindows) {
    Write-Warning "New-SelfSignedCertificate is Windows-only. Run this from a Windows host or a Windows CI job."
}

$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject $Subject `
    -KeyUsage DigitalSignature `
    -KeyAlgorithm RSA `
    -KeyLength 3072 `
    -FriendlyName "powerbi-openehr-aql Dev Cert" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(3)

$securePwd = ConvertTo-SecureString -String $Password -Force -AsPlainText

$pfxPath = Join-Path $OutputDir 'dev-cert.pfx'
$cerPath = Join-Path $OutputDir 'dev-cert.cer'

Export-PfxCertificate     -Cert $cert -FilePath $pfxPath -Password $securePwd | Out-Null
Export-Certificate        -Cert $cert -FilePath $cerPath                      | Out-Null

$pfxBytes  = [IO.File]::ReadAllBytes($pfxPath)
$pfxBase64 = [Convert]::ToBase64String($pfxBytes)

Write-Host "PFX  : $pfxPath"
Write-Host "CER  : $cerPath"
Write-Host ""
Write-Host "Store these in GitHub repo secrets:"
Write-Host "  CODE_SIGN_CERT_PASSWORD      = <the password you just used>"
Write-Host "  CODE_SIGN_CERT_PFX_BASE64    = (the base64 below)"
Write-Host ""
Write-Host $pfxBase64

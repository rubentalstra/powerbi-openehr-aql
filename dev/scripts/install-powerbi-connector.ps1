#!/usr/bin/env pwsh
# Install the signed OpenEHR.pqx connector for Power BI Desktop on Windows.
# Run from the folder containing OpenEHR.pqx and dev-cert.cer.
[CmdletBinding()]
param(
    [string]$ConnectorPath = ".\OpenEHR.pqx",
    [string]$CertificatePath = ".\dev-cert.cer",
    [switch]$SkipCertificateImport,
    [switch]$SkipTrustedThumbprint
)

$ErrorActionPreference = 'Stop'

if (-not $IsWindows) {
    throw "Power BI Desktop connector installation must be run on Windows."
}

$principal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script from an elevated PowerShell prompt. It writes LocalMachine certificate stores and HKLM policy."
}

$connector = Resolve-Path $ConnectorPath
$certificate = Resolve-Path $CertificatePath

$documents = [Environment]::GetFolderPath('MyDocuments')
if ([string]::IsNullOrWhiteSpace($documents)) {
    throw "Could not resolve the current user's Documents folder."
}

$dest = Join-Path $documents 'Microsoft Power BI Desktop\Custom Connectors'
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$targetConnector = Join-Path $dest 'OpenEHR.pqx'
Copy-Item $connector -Destination $targetConnector -Force
Unblock-File -Path $targetConnector -ErrorAction SilentlyContinue

$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certificate)
$thumbprint = $cert.Thumbprint.ToUpperInvariant()

if (-not $SkipCertificateImport) {
    Import-Certificate -FilePath $certificate -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
    Import-Certificate -FilePath $certificate -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null
}

if (-not $SkipTrustedThumbprint) {
    $policyPath = 'HKLM:\Software\Policies\Microsoft\Power BI Desktop'
    New-Item -Path $policyPath -Force | Out-Null
    $existing = (Get-ItemProperty -Path $policyPath -Name TrustedCertificateThumbprints -ErrorAction SilentlyContinue).TrustedCertificateThumbprints
    $values = @()
    if ($existing) {
        $values += @($existing)
    }
    if ($values -notcontains $thumbprint) {
        $values += $thumbprint
    }
    New-ItemProperty `
        -Path $policyPath `
        -Name TrustedCertificateThumbprints `
        -PropertyType MultiString `
        -Value $values `
        -Force | Out-Null
}

Write-Output "Installed connector: $targetConnector"
Write-Output "Trusted certificate thumbprint: $thumbprint"
Write-Output ""
Write-Output "Fully close and restart Power BI Desktop."
Write-Output "Connector location in Get Data: Other -> openEHR (Beta)"

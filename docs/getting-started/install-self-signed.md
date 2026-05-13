# Self-signed cert install (recommended for v0.1.0)

The v0.1.0 release is signed with a **self-signed** certificate. To load the connector without relaxing Power BI Desktop's security setting, trust the certificate thumbprint that signed the `.pqx`.

!!! info "Why self-signed?"
    A real EV/OV code-signing certificate (Sectigo, DigiCert, SSL.com) costs ~US$300–600/year. We want to validate the connector first and spend on a real cert once there's demand. See the [roadmap](https://github.com/rubentalstra/powerbi-openehr-aql/blob/main/ROADMAP.md) for when we plan to revisit this.

## Prerequisites

- Windows 10 or 11 with admin rights (trust-store import requires elevation).
- Power BI Desktop (Win32 installer build, not the Microsoft Store build).

## Step 1 — Download the release assets

From the latest [GitHub Release](https://github.com/rubentalstra/powerbi-openehr-aql/releases), grab:

- `OpenEHR.pqx` — the signed connector.
- `dev-cert.cer` — the public certificate.
- `install-powerbi-connector.ps1` — installs the connector and trust settings.
- `TRUSTED_CERTIFICATE_THUMBPRINT.txt` — the thumbprint used by Power BI Desktop trust policy.

## Step 2 — Install connector and trust settings

Open an **elevated** PowerShell prompt and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install-powerbi-connector.ps1
```

The script:

- Copies `OpenEHR.pqx` to the actual Power BI Desktop custom connector folder under your Windows Documents path.
- Imports `dev-cert.cer` into `LocalMachine\Root` and `LocalMachine\TrustedPublisher`.
- Adds the certificate thumbprint to `HKLM:\Software\Policies\Microsoft\Power BI Desktop\TrustedCertificateThumbprints`.

Microsoft documents this thumbprint registry value as the trust mechanism for signed third-party connectors under the Recommended security setting.

## Manual install

If you cannot use the script:

```powershell
$documents = [Environment]::GetFolderPath('MyDocuments')
$dest = Join-Path $documents 'Microsoft Power BI Desktop\Custom Connectors'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item .\OpenEHR.pqx -Destination $dest -Force
Unblock-File (Join-Path $dest 'OpenEHR.pqx')

Import-Certificate -FilePath .\dev-cert.cer -CertStoreLocation Cert:\LocalMachine\Root
Import-Certificate -FilePath .\dev-cert.cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher

$thumbprint = (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2('.\dev-cert.cer')).Thumbprint
$policyPath = 'HKLM:\Software\Policies\Microsoft\Power BI Desktop'
New-Item -Path $policyPath -Force | Out-Null
New-ItemProperty -Path $policyPath -Name TrustedCertificateThumbprints -PropertyType MultiString -Value $thumbprint -Force | Out-Null
```

## Step 3 — Restart Power BI Desktop

Fully quit Power BI Desktop and relaunch. The connector should appear at **Get Data → Other → openEHR (Beta)**.

## Verifying the signature

```powershell
$connector = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Microsoft Power BI Desktop\Custom Connectors\OpenEHR.pqx'
Get-AuthenticodeSignature $connector
Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Power BI Desktop' -Name TrustedCertificateThumbprints
```

Power BI Desktop trusts the `.pqx` when the certificate thumbprint appears in `TrustedCertificateThumbprints`. `Get-AuthenticodeSignature` can still report a self-signed chain nuance on some machines; the Power BI trust gate is the thumbprint policy.

## Troubleshooting

- **Connector does not appear** — verify the file is under `Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Microsoft Power BI Desktop\Custom Connectors'`, not `%USERPROFILE%\Documents\Power BI Desktop\Custom Connectors`.
- **Uncertified connector dialog appears** — the thumbprint policy is missing. Re-run Step 2 from an elevated prompt.
- **Gateway refresh fails with "untrusted publisher"** — same cert import must be performed on the gateway host. See [install-gateway-admin.md](install-gateway-admin.md).

[← Back to Home](../index.md)

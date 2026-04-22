# Self-signed cert install (recommended for v0.1.0)

The v0.1.0 release is signed with a **self-signed** certificate. To load the connector without relaxing Power BI Desktop's security setting, import the public `.cer` shipped with the release into Windows's trusted cert stores so the signature chains to a locally-trusted root.

!!! info "Why self-signed?"
    A real EV/OV code-signing certificate (Sectigo, DigiCert, SSL.com) costs ~US$300–600/year. We want to validate the connector first and spend on a real cert once there's demand. See the [roadmap](https://github.com/rubentalstra/powerbi-openehr-aql/blob/main/ROADMAP.md) for when we plan to revisit this.

## Prerequisites

- Windows 10 or 11 with admin rights (trust-store import requires elevation).
- Power BI Desktop (Win32 installer build, not the Microsoft Store build).

## Step 1 — Download the release assets

From the latest [GitHub Release](https://github.com/rubentalstra/powerbi-openehr-aql/releases), grab:

- `OpenEHR.pqx` — the signed connector.
- `dev-cert.cer` — the public certificate.

## Step 2 — Import the certificate (one-time)

Open an **elevated** PowerShell prompt and run:

```powershell
Import-Certificate -FilePath .\dev-cert.cer -CertStoreLocation Cert:\LocalMachine\Root
Import-Certificate -FilePath .\dev-cert.cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
```

The first import makes Windows trust the self-signed root. The second tells Power BI that publisher is explicitly trusted to sign custom connectors.

## Step 3 — Drop the connector into place

```powershell
$dest = "$env:USERPROFILE\Documents\Power BI Desktop\Custom Connectors"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item .\OpenEHR.pqx -Destination $dest -Force
```

## Step 4 — Restart Power BI Desktop

Fully quit Power BI Desktop and relaunch. **Get Data → Other → openEHR (Beta)** should now appear.

## Verifying the signature

```powershell
Get-AuthenticodeSignature "$env:USERPROFILE\Documents\Power BI Desktop\Custom Connectors\OpenEHR.pqx"
```

Status should be `Valid`. Signer subject should be `CN=powerbi-openehr-aql Dev Cert`.

## Troubleshooting

- **"The connector was not loaded because its signature is not valid"** — the `.cer` import did not take, or the PFX that signed `.pqx` was different from the `.cer` you imported. Re-run Step 2 from an elevated prompt.
- **Still see SmartScreen warnings on first open** — expected. Choose "Run anyway". After the first run, Windows should remember the trust decision.
- **Gateway refresh fails with "untrusted publisher"** — same cert import must be performed on the gateway host. See [install-gateway-admin.md](install-gateway-admin.md).

[← Back to Home](../index.md)

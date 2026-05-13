# End-user install

Step-by-step guide for **analysts** loading the connector on a personal Windows workstation. For gateway installs, see [Gateway admin install](install-gateway-admin.md).

## What you need

- Windows 10 or 11 with local admin rights.
- **Power BI Desktop** (Win32 installer build — the Microsoft Store build does not load custom connectors).
- Network access to your Clinical Data Repository — default EHRbase base URL is `http://<host>:8080/ehrbase/rest/openehr/v1`.

## The flow at a glance

```mermaid
flowchart TD
    A[Download<br/>OpenEHR.pqx + dev-cert.cer] --> B[Import cert<br/>LocalMachine\Root + TrustedPublisher]
    B --> C[Copy .pqx to<br/>Documents\Microsoft Power BI Desktop\Custom Connectors]
    C --> D[Restart Power BI Desktop]
    D --> E["Get Data → Other → openEHR (Beta)"]
    E --> F[Enter CDR base URL<br/>+ sign in]
```

## 1. Download the release

From the latest [GitHub Release](https://github.com/rubentalstra/powerbi-openehr-aql/releases) grab:

| File              | Purpose                                      |
| ----------------- | -------------------------------------------- |
| `OpenEHR.pqx`     | The signed connector.                        |
| `dev-cert.cer`    | The public cert — trust this once.           |
| `install-powerbi-connector.ps1` | One-command Windows install helper. |
| `SHA256SUMS.txt`  | Verify integrity before installing.          |

Verify checksums in an elevated PowerShell prompt:

```powershell
Get-FileHash .\OpenEHR.pqx -Algorithm SHA256
Get-Content .\SHA256SUMS.txt | Select-String OpenEHR.pqx
```

## 2. Install and trust the connector

v0.1.0 ships with a **self-signed** cert. Run the installer from an elevated PowerShell prompt:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install-powerbi-connector.ps1
```

The installer copies the `.pqx` to the correct Documents-scoped folder, imports the public cert, and writes Power BI Desktop's trusted thumbprint policy. Full rationale + manual commands: [Self-signed cert install](install-self-signed.md).

## 3. Power BI Desktop settings

Keep **File → Options → Security → Data Extensions** at the default:

> **(Recommended) Only allow Microsoft certified and other trusted third-party extensions to load**

If you skip signing/thumbprint trust and only want a quick local smoke test, use the [unsigned/evaluation path](install-uncertified.md) instead.

## 4. First sign-in

1. Fully quit and relaunch Power BI Desktop.
2. **Get Data → Other → openEHR (Beta) → Connect**.
3. Enter your CDR base URL, e.g. `http://localhost:8080/ehrbase/rest/openehr/v1`.
4. Choose an authentication method:
    - **Username and password** — [Basic auth](../auth/basic.md)
    - **Organizational account (OAuth)** — [OAuth PKCE](../auth/oauth-pkce.md) / [Entra ID](../auth/entra-id.md)
5. The **Navigator** opens with four folders: **Ad-hoc AQL**, **Stored Queries**, **Templates**, **EHRs**.

## Uninstalling

```powershell
$connector = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Microsoft Power BI Desktop\Custom Connectors\OpenEHR.pqx'
Remove-Item $connector
# Optional: also remove cached credentials in Power BI Desktop
# File → Options → Data source settings → Global permissions → Clear
```

## Next steps

- **Write your first query** — [Blood-pressure trend cookbook](../cookbook/blood-pressure-trend.md).
- **Schedule refresh** — [Gateway admin install](install-gateway-admin.md) (ask your IT team).
- **Something's wrong** — [Troubleshooting](../troubleshooting.md).

[← Back to Home](../index.md)

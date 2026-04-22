# Self-signed cert install (recommended for v0.1.0)

The v0.1.0 release is signed with a self-signed certificate. To load it without relaxing Power BI Desktop's security setting, install the public `.cer` from the release into two Windows certificate stores so the signature chains to a machine-trusted root.

Coming soon — full PowerShell one-liner + screenshots. Until then, the short version:

```powershell
# Run from an elevated PowerShell prompt, in the folder where you downloaded dev-cert.cer
Import-Certificate -FilePath dev-cert.cer -CertStoreLocation Cert:\LocalMachine\Root
Import-Certificate -FilePath dev-cert.cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
```

Then copy `OpenEHR.pqx` to `%USERPROFILE%\Documents\Power BI Desktop\Custom Connectors\` and restart Power BI Desktop.

[← Back to Home](../index.md)

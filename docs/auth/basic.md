# Basic authentication

HTTP Basic auth — the simplest option, and what EHRbase runs with by default (`SECURITY_AUTHTYPE=BASIC`).

## When to use

- Self-hosted EHRbase / a CDR with no identity provider in front of it.
- Dev / proof-of-concept setups.
- CI integration tests.

## When **not** to use

- Any deployment carrying real PHI. Basic credentials travel on every request; if the connection is not HTTPS end-to-end, they are trivially sniffable.
- Tenants that use federated identity (Entra, Okta, Keycloak) — use [OAuth PKCE](oauth-pkce.md) instead.

## Sign-in flow

1. **Get Data → Other → openEHR (Beta)**.
2. Enter the CDR base URL (e.g. `http://localhost:8080/ehrbase/rest/openehr/v1`).
3. Pick **Username and password** on the credentials dialog.
4. Enter the CDR's username and password. Power BI stores them in the Windows credential store, keyed by data source path.

The connector builds the `Authorization: Basic <base64(user:pass)>` header on every request. The credential is never passed as a function argument — it comes from `Extension.CurrentCredential()` at call time, which is why rotating passwords works without editing queries.

## Gateway refresh

Basic credentials work through the on-premises gateway out of the box. On the gateway admin UI, choose **Windows** → **Username and password** and re-enter.

## Troubleshooting

- `HTTP 401` after a recent password change — clear and re-enter the credential: **File → Options → Data source settings → Clear permissions**.
- `HTTP 401` on a freshly-seeded EHRbase — confirm `SECURITY_AUTHTYPE=BASIC` and the `SECURITY_AUTHUSER` / `SECURITY_AUTHPASSWORD` env vars match what you entered.
- All requests work interactively but gateway refresh fails silently — this is almost always a missing `TestConnection` handler. Use the official release, not a hand-hacked `.mez`.

[← Back to Home](../index.md)

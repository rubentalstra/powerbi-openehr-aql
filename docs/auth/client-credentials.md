# Client credentials (service principal)

OAuth's `client_credentials` grant is a **machine-to-machine** flow: no user, no browser, no refresh token. A service principal presents a client ID + secret (or certificate) and receives a short-lived access token.

> **Compatibility note.** Power BI's custom-connector runtime does not natively expose the `client_credentials` grant through the `OAuth` kind (which is built around authorization-code + refresh). The two supported patterns for headless refresh are described below.

## Pattern 1 — Basic auth with a service account (recommended for EHRbase / self-hosted CDRs)

Create a dedicated service account in the CDR whose password is rotated by your secrets manager. Use it with [Basic auth](basic.md). This is the simplest path and works through the on-premises gateway unmodified.

**When to prefer this:** EHRbase, Better Platform in self-hosted mode, DIPS, Code24 — any CDR where you control the account store.

## Pattern 2 — OAuth PKCE with a long-lived refresh principal (recommended for Entra ID)

Sign in interactively once as a dedicated "Power BI refresh" identity (user principal, not service principal), then let Power BI's refresh-token mechanism carry the grant forward. The principal's refresh token typically lives 60–90 days; the gateway refreshes it silently on each scheduled run.

**When to prefer this:** Entra ID-fronted CDRs, or any IDP whose `client_credentials` tokens do not include the audience claim your CDR requires.

Configuration: [OAuth PKCE](oauth-pkce.md), then on the gateway sign in as the refresh principal.

## Pattern 3 — Out-of-band token broker (advanced)

If neither of the above fits — e.g. corporate policy requires `client_credentials` — the typical workaround is to run a thin broker service inside your network that:

1. Holds the service-principal secret.
2. Issues short-lived access tokens on request.
3. Is fronted by Basic auth that the connector speaks to.

The connector sees Basic auth; the broker handles `client_credentials` against the IDP. This keeps the secret off the gateway host.

## Why not native `client_credentials` in the connector?

Two reasons:

1. **No secret storage.** The `.pqx` ships as a published artifact; embedding a client secret would leak it to every installer.
2. **No refresh semantics.** `client_credentials` tokens are not renewable — you must request a fresh one every time. Power BI's credential cache is designed around refresh-token rotation, so every request would hit the token endpoint, which breaks under rate limits and inflates latency.

If your deployment specifically needs `client_credentials`, open a [feature request](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=feature_request.yml) describing the deployment topology — we are tracking demand.

[← Back to Home](../index.md)

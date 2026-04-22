# OAuth 2.0 with PKCE

Interactive user sign-in against any OpenID Connect provider — Keycloak, Auth0, Okta, Entra ID. The connector runs the **authorization-code flow with PKCE** (RFC 7636), so no client secret is embedded in the `.pqx`.

## Flow at a glance

```
Power BI Desktop              OpenEHR connector                   IDP (Keycloak / Entra / …)
      │                              │                                     │
      │  Get Data → openEHR (OAuth)  │                                     │
      │─────────────────────────────▶│                                     │
      │                              │ code_verifier = random 64-char      │
      │                              │ code_challenge = S256(verifier)     │
      │                              │                                     │
      │                              │ StartLogin → authorize URL          │
      │◀─────── embedded browser ────┤                                     │
      │                              │   user signs in, consents           │
      │                              │─────────────────────────────────────▶│
      │                              │◀────── code + state ────────────────│
      │                              │                                     │
      │                              │ FinishLogin: POST /token            │
      │                              │   code + code_verifier + client_id  │
      │                              │─────────────────────────────────────▶│
      │                              │◀── access_token + refresh_token ────│
      │                              │                                     │
      │           (table data)       │                                     │
      │◀─────────────────────────────│ AQL calls with Authorization: Bearer│
      │                              │─────────────────────────────────────▶│
```

Power BI stores the token bundle in the Windows credential store. When the access token expires, `Refresh` is invoked automatically with the refresh token.

## One-time IDP registration

Before the connector can sign in, your IDP administrator needs an app registered as a **public client** (no secret) with these settings:

| Setting               | Value                                                                     |
| --------------------- | ------------------------------------------------------------------------- |
| Client type           | Public (no client secret)                                                 |
| Grant type            | Authorization code                                                        |
| PKCE                  | Required, method **S256**                                                 |
| Redirect URI          | `https://oauth.powerbi.com/views/oauthredirect.html`                       |
| Refresh tokens        | Enabled (Entra: include `offline_access` in scopes)                        |
| Scopes                | `openid`, `profile`, `offline_access`, **plus** whatever audience scope your CDR protects itself with |

Take the Client ID, the authorize endpoint, the token endpoint, and (optionally) the end-session / logout endpoint.

## Configuring the connector

The connector's OAuth parameters live in `OpenEHR.OAuthConfig` at the top of [`src/OpenEHR.pq`](https://github.com/rubentalstra/powerbi-openehr-aql/blob/main/src/OpenEHR.pq):

```m
OpenEHR.OAuthConfig = [
    ClientId     = "<your-registered-client-id>",
    AuthorizeUri = "https://<idp-host>/.../authorize",
    TokenUri     = "https://<idp-host>/.../token",
    LogoutUri    = "https://<idp-host>/.../logout",
    RedirectUri  = "https://oauth.powerbi.com/views/oauthredirect.html",
    Scopes       = { "openid", "profile", "offline_access" }
];
```

Defaults target **Entra ID / `common` tenant**. For Keycloak, replace `AuthorizeUri` / `TokenUri` / `LogoutUri` with the realm's OIDC endpoints (`/realms/<realm>/protocol/openid-connect/{auth,token,logout}`).

You need to rebuild and re-sign after editing this record. See [install-self-signed.md](../getting-started/install-self-signed.md).

## Sign-in flow (end-user)

1. **Get Data → Other → openEHR (Beta)**.
2. Enter the CDR base URL.
3. Pick **Organizational account (OAuth)** on the credentials dialog.
4. A browser window opens; complete sign-in + consent.
5. Close the window; Power BI caches the token bundle and the table loads.

## Gateway refresh

The on-premises gateway re-invokes `Refresh` with the stored refresh token. The admin must:

1. Install the `.pqx` and import the signing cert on the gateway host ([see gateway guide](../getting-started/install-gateway-admin.md)).
2. On the data source in the Power BI service, choose **OAuth** and sign in once as the refresh principal.

If the refresh token expires (varies per IDP; Entra defaults to 90 days of inactivity), gateway refresh pauses and the dataset owner must re-authenticate.

## Troubleshooting

- **`AADSTS50011: reply URL does not match`** — the redirect URI registered on the IDP app doesn't EXACTLY match `https://oauth.powerbi.com/views/oauthredirect.html`. Trailing slash counts.
- **Browser window closes immediately / empty callback** — Pop-up blocker or strict tracking-prevention. Allow-list `oauth.powerbi.com`.
- **`invalid_grant` on refresh** — the refresh token was revoked or expired. Clear the credential in **File → Options → Data source settings** and sign in again.
- **`invalid_client`** — ClientId doesn't exist on the IDP, or it was registered as a confidential client (needs secret). Re-register as public.
- **Works in Desktop, fails on gateway** — the cert signing the `.pqx` must be imported into the gateway host's `LocalMachine\TrustedPublisher` store. See [install-self-signed.md](../getting-started/install-self-signed.md#troubleshooting).

## Related

- [Entra ID-specific configuration](entra-id.md)
- [Client credentials flow](client-credentials.md) for headless refresh with no user

[← Back to Home](../index.md)

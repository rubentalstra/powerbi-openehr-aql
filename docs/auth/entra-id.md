# Microsoft Entra ID

The connector's OAuth defaults target **Entra ID v2** (`login.microsoftonline.com`). This page covers the Entra-specific registration and config steps.

## 1. Register the app

In the Azure portal, **Entra ID → App registrations → New registration**:

| Field                   | Value                                                                          |
| ----------------------- | ------------------------------------------------------------------------------ |
| Name                    | `powerbi-openehr-aql` (or your fork's name)                                    |
| Supported account types | "Accounts in this organizational directory only" (single-tenant) — or multi-tenant if distributing |
| Redirect URI — platform | **Public client/native (mobile & desktop)**                                    |
| Redirect URI — value    | `https://oauth.powerbi.com/views/oauthredirect.html`                             |

Do **not** create a confidential "Web" app — the connector uses PKCE as a public client with no secret.

## 2. Configure API permissions

**API permissions → Add a permission** → pick the API your CDR is protected with:

- **Self-hosted EHRbase fronted by Entra** — typically an app you registered to represent the CDR API. Add its `openid`, `profile`, `offline_access`, and any app-scoped permission (e.g. `aql.read`).
- **Third-party CDR as SaaS** — use the vendor's published application ID URI; add their documented scope.

`offline_access` is **required** for refresh-token issuance. Without it, gateway refresh stops working after the initial token expires.

## 3. Grant consent

Either admin-consent the permissions in the portal, or let the first user consent interactively at sign-in. Admin consent is preferred for shared datasets.

## 4. Plug the values into the connector

Edit [`src/OpenEHR.pq`](https://github.com/rubentalstra/powerbi-openehr-aql/blob/main/src/OpenEHR.pq):

```m
OpenEHR.OAuthConfig = [
    ClientId     = "<Application (client) ID from the portal>",

    // Single-tenant: replace `common` with your tenant GUID or verified domain.
    AuthorizeUri = "https://login.microsoftonline.com/<tenant>/oauth2/v2.0/authorize",
    TokenUri     = "https://login.microsoftonline.com/<tenant>/oauth2/v2.0/token",
    LogoutUri    = "https://login.microsoftonline.com/<tenant>/oauth2/v2.0/logout",

    RedirectUri  = "https://oauth.powerbi.com/views/oauthredirect.html",

    // `openid profile offline_access` + your CDR's protected scope.
    // Example (Entra-exposed EHRbase app): add "api://<cdr-app-id>/aql.read".
    Scopes       = { "openid", "profile", "offline_access", "api://<cdr-app-id>/aql.read" }
];
```

Rebuild + re-sign ([install-self-signed.md](../getting-started/install-self-signed.md)).

## Why not use the built-in `Aad` authentication kind?

Power Query M has an `Aad` auth kind (sometimes called `AadWithFederatedAuth`) that's hardwired to Microsoft's first-party identity flow. It was deprecated for external connectors in favour of generic OAuth + the Entra endpoints. Using the plain `OAuth` kind with v2 endpoints:

- Works identically inside and outside the Microsoft cloud.
- Lets you point at Keycloak / Okta / Auth0 with only endpoint changes.
- Is the only path supported by the current Power Query SDK template.

## Multi-tenant distribution

If you publish a `.pqx` for other organisations to install:

1. Use the `common` authority (or `organizations`) in `AuthorizeUri` / `TokenUri`.
2. Register the app as **multi-tenant**.
3. In API permissions, request only delegated scopes — admin-consent on each tenant.
4. Document that installers must admin-consent the app in their own tenant before first sign-in (`https://login.microsoftonline.com/<tenant>/adminconsent?client_id=<your-client-id>`).

## Troubleshooting

- **`AADSTS65001: user has not consented`** — admin hasn't consented in the target tenant. Visit the admin-consent URL above or grant per-user consent on first sign-in.
- **`AADSTS700016: application not found in the directory`** — ClientId is wrong for the tenant being signed into. Double-check single-tenant vs multi-tenant registration.
- **`AADSTS70011: invalid scope`** — the API permission wasn't added or wasn't consented. Re-check step 2.
- **Gateway refresh works, interactive Desktop doesn't** — conditional-access policy is blocking the Power BI Desktop client. Ask your tenant admin.

## Related

- [OAuth PKCE (generic)](oauth-pkce.md)
- [Client credentials / service principal](client-credentials.md)
- [Entra docs — authorization-code flow](https://learn.microsoft.com/entra/identity-platform/v2-oauth2-auth-code-flow)

[← Back to Home](../index.md)

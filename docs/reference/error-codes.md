# Error codes

All errors raised by the connector use the `OpenEHR.*` reason family.

| Reason | HTTP trigger | Meaning |
|---|---|---|
| `OpenEHR.AqlError` | 400 | Server rejected the AQL (syntax, unknown archetype, ...). |
| `OpenEHR.AuthError` | 401, 403 | Credentials missing, wrong, or insufficient. |
| `OpenEHR.TimeoutError` | 408 | Server took longer than `Timeout`. |
| `OpenEHR.ConflictError` | 409 | State conflict (duplicate template, modified composition, ...). |
| `OpenEHR.NotFoundError` | 404 | Resource does not exist. |
| `OpenEHR.HttpError` | other | Anything else. |

Full details coming soon.

[← Back to Home](../index.md)

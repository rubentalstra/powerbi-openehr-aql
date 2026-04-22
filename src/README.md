# Connector workspace

`src/` is the Power Query SDK workspace for this repository.

It contains:

- `OpenEHR.pq`
- `OpenEHR.query.pq`
- `*.pqm`
- `resources.resx`
- `OpenEHR{16,20,24,32,40,48}.png`
- `.pqignore`
- `.vscode/settings.json`

Build from this directory with:

```powershell
MakePQX compile . -t OpenEHR
```

If you want both the repo and connector open in VS Code, use `powerbi-openehr-aql.code-workspace` and run Power Query SDK commands against the `connector` folder.

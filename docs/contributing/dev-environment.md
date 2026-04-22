# Dev environment

See [CONTRIBUTING.md](https://github.com/rubentalstra/powerbi-openehr-aql/blob/main/CONTRIBUTING.md) for the full setup.

Short version:

```bash
cd dev
cp .env.example .env
docker compose up -d
bash scripts/check-health.sh
bash scripts/load-seed.sh
```

[← Back to Home](../index.md)

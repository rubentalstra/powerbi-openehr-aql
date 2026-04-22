---
description: Cut a release — bump version, update CHANGELOG, tag, push.
argument-hint: "<semver, e.g. 0.1.0>"
---

## Context

Releases are triggered by a `v*` tag on `main`. The tag drives `.github/workflows/release.yml`, which builds, signs, and publishes the `.pqx` + `.cer` to GitHub Releases.

## Instructions

1. Verify `main` is green (`gh run list --workflow=ci.yml --branch=main --limit=1`).
2. Update `version.txt` (create if missing) with the new semver.
3. In `CHANGELOG.md`, convert the `[Unreleased]` section to `[<version>] — <YYYY-MM-DD>`; open a fresh empty `[Unreleased]`.
4. Show the user the diff and the proposed tag command:

```
git add version.txt CHANGELOG.md
git commit -m "chore(release): v$ARGUMENTS"
git tag -a "v$ARGUMENTS" -m "v$ARGUMENTS"
git push origin main "v$ARGUMENTS"
```

Stop. The user runs git operations manually (see CLAUDE.md — Never do).

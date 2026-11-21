# CLAUDE.md

Guidance for Claude Code when working in this repository.

> ## 📖 Read the architecture docs first
> The overall Cloud Build / deploy / Terraform architecture is design-platform's
> **`build`** area: `design-platform:docs/design/build/overview.md`, read with
> dz-context's `read_file`.

## Standards and the check

This is an `ops` repo (`dz/project.yaml`): ai-harness's `ops-standards` rules (`OPS-`)
apply, with its general and security rules, and design-platform's `build` design rules
(`BLD-`), which it names under `designs:`. They cover secrets, cloud commands, installing and
shell scripts across the `Build/` repos; this file keeps only what's true of this repo.
**The check** is `bash check.sh` (`commands.build`): `build-maven.sh` and
`maven-settings.xml` parse. It runs offline and writes nothing.

## What this repo is

**Shared Cloud Build logic for building WARs and Java libraries.** Other repos'
`cloudbuild.yaml` files `git clone` this repo and run its script — the build
steps live here once, not copied per project.

- `build-maven.sh` — configures `settings.xml` with a gcloud access token,
  computes the project version, configures GitHub credentials from Secret
  Manager (`deployza-github-fine-grained-token`, a fine-grained PAT with
  Contents:write), runs
  `mvn clean deploy`, then tags the source commit with the release version and
  pushes the tag to `github.com`.
- `maven-settings.xml` — Artifact Registry Maven server auth; the
  `__ACCESS_TOKEN__` placeholder is replaced at build time.

## Gotchas

- This repo was renamed (`build-scripts` → `build-app-scripts` → `build-apps`).
  Callers (e.g. `build-parent-pom/cloudbuild.yaml`) clone
  `https://github.com/deployza/build-apps.git`. Watch for any out-of-workspace
  callers still using an old name.
- Source is on GitHub via Cloud Build's Git connector (browser OAuth). The
  connector's token (`deployza-github-github-oauthtoken-f606bd` in `dz-builds`)
  is read-only and cannot push — pushing tags with it returns HTTP 403. So
  tagging uses a separate fine-grained PAT (Contents:write) stored in
  `deployza-github-fine-grained-token` (also in `dz-builds`). That PAT expires
  (≤1 year) and must be rotated.
- Secrets come from Secret Manager; never hardcode tokens here (OPS-01).

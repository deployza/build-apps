# CLAUDE.md

Guidance for Claude Code when working in this repository.

> ## 📖 Read the architecture docs first
> The overall Cloud Build / deploy / Terraform architecture lives in the
> **`build-docs`** repo, cloned as a sibling of this one:
> [`../build-docs/README.md`](../build-docs/README.md).
>
> **If that path does not exist, you have not cloned `build-docs` yet — stop and
> clone it first** (it sits next to this repo under `Build/`):
> ```bash
> git clone https://bitbucket.org/deployza/build-docs.git
> ```
> Without it you are missing the cross-repo context.

## What this repo is

**Shared Cloud Build logic for building WARs and Java libraries.** Other repos'
`cloudbuild.yaml` files `git clone` this repo and run its script — the build
steps live here once, not copied per project.

- `build-maven.sh` — configures `settings.xml` with a gcloud access token,
  computes the project version, configures Bitbucket credentials from Secret
  Manager (`bitbucket-admin-api-token`), runs `mvn clean deploy`, then tags the
  source commit with the release version.
- `maven-settings.xml` — Artifact Registry Maven server auth; the
  `__ACCESS_TOKEN__` placeholder is replaced at build time.

## Gotchas

- This repo was renamed from `build-scripts`. Some callers (e.g.
  `build-parent-pom/cloudbuild.yaml`) still clone the old name — update them.
- Secrets come from Secret Manager; never hardcode tokens here.

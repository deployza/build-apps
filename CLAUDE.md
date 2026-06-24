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
  computes the project version, configures GitHub credentials from Secret
  Manager (`github-github-oauthtoken-fd49dd`, the token created by Cloud Build's
  Git/GitHub connector), runs `mvn clean deploy`, then tags the source commit
  with the release version and pushes the tag to `github.com`.
- `maven-settings.xml` — Artifact Registry Maven server auth; the
  `__ACCESS_TOKEN__` placeholder is replaced at build time.

## Gotchas

- This repo was renamed (`build-scripts` → `build-app-scripts` → `build-apps`).
  In-workspace callers (e.g. `build-parent-pom/cloudbuild.yaml`) now clone
  `build-apps`; the upstream repo must be renamed to match. Watch for any
  out-of-workspace callers still using an old name.
- Source is on GitHub via Cloud Build's Git connector (browser OAuth). The
  connector stores its OAuth token in the `github-github-oauthtoken-fd49dd`
  secret; `build-maven.sh` reads it to push release tags. The old
  `bitbucket-admin-api-token` secret is no longer used by this script.
- Secrets come from Secret Manager; never hardcode tokens here.

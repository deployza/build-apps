# build-apps

## What it does

The shared Cloud Build logic that builds WARs and Java libraries, kept once here rather
than copied into each project: `build-maven.sh` configures Maven's `settings.xml` with the
build's gcloud access token, computes the version, runs `mvn clean deploy`, then tags the
source commit with the release version and pushes the tag to GitHub.
`maven-settings.xml` is the Artifact Registry server auth, its token substituted at build
time.

## Where it runs

In Cloud Build, in the `maven-docker` image: each Java project's `cloudbuild.yaml` clones
this repo and runs `build-maven.sh` (`build-parent-pom`'s does).

## How it fits

It is the build step of the design's build → deploy → infra flow: the WARs it deploys to
Artifact Registry are what `build-ops` installs on a host.

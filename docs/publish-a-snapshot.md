# Publishing a snapshot from your own machine

A developer publishes an app's `-SNAPSHOT` to Artifact Registry from their own machine with
`mvn deploy`, because Cloud Build is too slow for every change. Only Cloud Build publishes a
release (design-platform's BLD-24), through this repo's `build-maven.sh`. Every artifact,
snapshot or release, goes to the Maven repositories and nowhere else (BLD-23): no copy goes
into a bucket.

## Who can

The developer groups, `gcp-api` and `gcp-ziniapps`, hold `roles/artifactregistry.writer` on
`private-snapshot-taiwan` and nothing more. They read `private-release-taiwan` and the two
Maven Central remotes, `maven-central-taiwan` and `maven-central-plugin-taiwan`, so a laptop
build resolves everything straight from Artifact Registry. The grants are build-terraform's
(`dz-builds/artifact-registry.tf`).

## Setting up, once

1. **Sign in to gcloud** as yourself: `gcloud auth login`. Maven uses your own credentials,
   never a service account's key.
2. **Write `~/.m2/settings.xml`.** Its passwords come from the `AR_TOKEN` environment
   variable. This repo's `maven-settings.xml` is for Cloud Build only: `build-maven.sh`
   substitutes its `__ACCESS_TOKEN__` (BLD-5), and a token lasts only an hour, so a laptop
   can't keep one in a file.

   ```xml
   <settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd">
     <servers>
       <server>
         <id>private-release-taiwan</id>
         <username>oauth2accesstoken</username>
         <password>${env.AR_TOKEN}</password>
       </server>
       <server>
         <id>private-snapshot-taiwan</id>
         <username>oauth2accesstoken</username>
         <password>${env.AR_TOKEN}</password>
       </server>
       <server>
         <id>maven-central-taiwan</id>
         <username>oauth2accesstoken</username>
         <password>${env.AR_TOKEN}</password>
       </server>
       <server>
         <id>maven-central-plugin-taiwan</id>
         <username>oauth2accesstoken</username>
         <password>${env.AR_TOKEN}</password>
       </server>
     </servers>

     <!-- Lets Maven fetch deployza-parent-pom itself: the parent's own <repositories>
          apply only once the parent has been read. -->
     <profiles>
       <profile>
         <id>deployza-artifact-registry</id>
         <repositories>
           <repository>
             <id>private-release-taiwan</id>
             <url>https://asia-east1-maven.pkg.dev/dz-builds/private-release-taiwan</url>
             <releases><enabled>true</enabled></releases>
             <snapshots><enabled>false</enabled></snapshots>
           </repository>
           <repository>
             <id>private-snapshot-taiwan</id>
             <url>https://asia-east1-maven.pkg.dev/dz-builds/private-snapshot-taiwan</url>
             <releases><enabled>false</enabled></releases>
             <snapshots><enabled>true</enabled></snapshots>
           </repository>
         </repositories>
       </profile>
     </profiles>

     <activeProfiles>
       <activeProfile>deployza-artifact-registry</activeProfile>
     </activeProfiles>
   </settings>
   ```

3. **Have Maven fetch a fresh token on every run.** Maven 3 runs a startup file before each
   `mvn`, so no shell has to set `AR_TOKEN`:

   - Git Bash, Linux or macOS, `~/.mavenrc`:

     ```bash
     export AR_TOKEN="$(gcloud auth print-access-token)"
     ```

   - cmd or PowerShell on Windows, `%USERPROFILE%\mavenrc_pre.cmd`:

     ```bat
     @for /f "usebackq delims=" %%t in (`gcloud auth print-access-token`) do @set "AR_TOKEN=%%t"
     ```

   If `gcloud` can't run from Git Bash (it can fail to find Python there), run `mvn` from
   PowerShell instead.

**Why a token, not the Artifact Registry wagon:** the token is how Cloud Build signs in
(BLD-5), so a laptop and a build share the same `<server>` ids and URLs, and no project's
POM needs a build extension.

## Publishing a snapshot

In the app's repo, on a commit whose `pom.xml` version ends in `-SNAPSHOT`:

```bash
mvn clean deploy
```

The parent POM's `<distributionManagement>` sends a `-SNAPSHOT` to `private-snapshot-taiwan`,
stored under a timestamped build (`2.0-20261125.093012-3`), which is the snapshot's newest
build from then on. Nothing is tagged: `build-maven.sh` tags only what Cloud Build publishes.

To see it there:

```bash
gcloud artifacts versions list --project=dz-builds --location=asia-east1 \
  --repository=private-snapshot-taiwan --package=<groupId>:<artifactId>
```

## Naming it in a target

A host deploys what its target in the release bucket, `gs://dz-builds-releases`, names. The
bucket's working copy is build-ops-data, whose `CLAUDE.md` (_How it's used_) has the steps
and the sync commands.

- **The target already names this `-SNAPSHOT`:** push the host from build-ops' `ansible/`
  folder (`cd ansible && ansible-playbook playbooks/<host>.yml --tags <app>`). A `-SNAPSHOT`
  version deploys its newest build, and the deploy log records which one it got.
- **A new `-SNAPSHOT` version:** add `versions/<app>/<version>/` in build-ops-data, with its
  `version.properties` and full `templates/` (BLD-25), and change the app's line in
  `vm-targets/<host>/target.properties`, with the app's files if the format changed. Sync
  both, then push.

A snapshot's earlier build can't be named again: to roll back, name a release.

## A release from your machine fails

A version without `-SNAPSHOT` goes to `private-release-taiwan`, which the developer groups
can only read, so the upload fails with `403 Forbidden`. That's on purpose (BLD-24): a
release is built only by Cloud Build, from a pushed commit, and tagged there. Publish a
snapshot instead, or push the commit and let the app's trigger build the release.

IAM doesn't stop everyone: `dz-builds`' owners and editors, and `gcp-devops`, can write
`private-release-taiwan`, so for them a release from a laptop would succeed. Don't: the
repository is release-only, and a stray release would take the version number from the
real build.

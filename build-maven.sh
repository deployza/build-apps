#!/bin/bash

#exit on any error
set -e  

# CONFIGURE MAVEN SETTINGS.XML
echo "***** configuring settings.xml"
mkdir -p /workspace/.m2
cp ./build-apps/maven-settings.xml /workspace/.m2/settings.xml

#get ACCESS Token
ACCESS_TOKEN=$(gcloud auth print-access-token)
#Replace in the settings.xml
sed -i "s|__ACCESS_TOKEN__|${ACCESS_TOKEN}|" /workspace/.m2/settings.xml

# CONFIGURE VERSION.TXT
#Get build version and put in a file
echo "***** configuring version.txt"
VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout -s /workspace/.m2/settings.xml)

echo "VERSION=$VERSION" >> /workspace/version.txt

# CONFIGURE GITHUB CREDENTIALS
echo "***** configuring .git-credentials"
# Cloud Build's GitHub (Git) connector stores the OAuth token in this secret.
GITHUB_TOKEN="$(gcloud secrets versions access latest --secret=github-github-oauthtoken-fd49dd)"

# Configure the credential helper to use a file-backed store
 # The syntax is https://<username>:<token>@<host>
git config --global credential.helper 'store --file=/workspace/.git-credentials'

# Add the credentials to the file
echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > /workspace/.git-credentials

# RUN MAVEN
echo "***** runing maven"
mvn -B -s /workspace/.m2/settings.xml -Dmaven.repo.local=/workspace/.m2 clean deploy

#TAG SOURCE CODE
echo "***** tagging source code"
source /workspace/version.txt
git config user.email "cloudromilbuild@ydeployza.com"
git config user.name "Cloud Build"
git tag -a "${VERSION}" -m "Release ${VERSION}"
git push origin "${VERSION}" --force




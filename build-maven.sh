#!/bin/bash

set -e  

# CONFIGURE MAVEN SETTINGS.XML
echo "***** configuring settings.xml"

#Create .m2 directory
mkdir -p /workspace/.m2

#Create settings.xml

cp ./build-scripts/maven-settings.xml /workspace/.m2/settings.xml

#get ACCESS Token
ACCESS_TOKEN=$(gcloud auth print-access-token)

#Replace in the settings.xml
sed -i "s|__ACCESS_TOKEN__|${ACCESS_TOKEN}|" /workspace/.m2/settings.xml

# CONFIGURE VERSION.TXT

echo "***** configuring version.txt"

#Get build version and put in a file
mvn help:evaluate -Dexpression=project.version -q -DforceStdout -s /workspace/.m2/settings.xml
VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout -s /workspace/.m2/settings.xml)

echo "VERSION=$VERSION" >> /workspace/version.txt

# CONFIGURE BITBUCKET CREDENTIALS

echo "***** configuring .git-credentials"
# Use gcloud to retrieve the token (same as Solution 1) --project=$PROJECT_ID
BITBUCKET_TOKEN="$(gcloud secrets versions access latest --secret=bitbucket-admin-api-token)"

# Configure the credential helper to use a memory cache
 # The syntax is https://<username>:<token>@<host>
git config --global credential.helper 'store --file=/workspace/.git-credentials'
#git config --global url."https://x-token-auth:${BITBUCKET_TOKEN}@bitbucket.org".insteadOf "https://bitbucket.org"


# Add the credentials to the file
echo "https://x-token-auth:${BITBUCKET_TOKEN}@bitbucket.org" > /workspace/.git-credentials

# RUN MAVEN
echo "***** runing maven"
mvn -B -s /workspace/.m2/settings.xml -Dmaven.repo.local=/workspace/.m2 clean deploy

#TAG SOURCE CODE

echo "***** tagging source code"
#source /workspace/version.txt
git config user.email "cloudbuild@ydeployza.com"
git config user.name "Cloud Build"
git tag -a "${VERSION}" -m "Release ${VERSION}"
git push origin "${VERSION}" --force




#!/bin/bash

set -e  

# CONFIGURE MAVEN SETTINGS.XML
echo "***** configuring settings.xml"

#Create .m2 directory
mkdir -p /workspace/.m2

#Create settings.xml

cat > /workspace/.m2/settings.xml <<"EOF"
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>private-snapshot-taiwan</id>
      <username>oauth2accesstoken</username>
      <password>__ACCESS_TOKEN__</password>
    </server>
    <server>
      <id>private-release-taiwan</id>
      <username>oauth2accesstoken</username>
      <password>__ACCESS_TOKEN__</password>
    </server>    
    <server>
      <id>maven-central-taiwan</id>
      <username>oauth2accesstoken</username>
      <password>__ACCESS_TOKEN__</password>
    </server>    
    <server>
      <id>maven-central-plugin-taiwan</id>
      <username>oauth2accesstoken</username>
      <password>__ACCESS_TOKEN__</password>
    </server>    
  </servers>
</settings>

EOF

#get ACCESS Token
ACCESS_TOKEN=$(gcloud auth print-access-token)

#Replace in the settings.xml
sed -i "s|__ACCESS_TOKEN__|${ACCESS_TOKEN}|" /workspace/.m2/settings.xml

# CONFIGURE VERSION.TXT

echo "***** configuring version.txt"

#Get build version and put in a file
VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)

echo "***** step 09"

echo "VERSION=$VERSION" >> /workspace/version.txt


# CONFIGURE BITBUCKET CREDENTIALS

echo "***** configuring .git-credentials"
# Use gcloud to retrieve the token (same as Solution 1) --project=$PROJECT_ID
BITBUCKET_TOKEN="$(gcloud secrets versions access latest --secret=bitbucket-admin-api-token)"

# Configure the credential helper to use a memory cache
 # The syntax is https://<username>:<token>@<host>
git config --global credential.helper 'store --file=/workspace/.git-credentials'
#git config --global url."https://x-token-auth:${BITBUCKET_TOKEN}@bitbucket.org".insteadOf "https://bitbucket.org"

echo "***** step 10"

# Add the credentials to the file
echo "https://x-token-auth:${BITBUCKET_TOKEN}@bitbucket.org" > /workspace/.git-credentials

echo "***** step 11"

# RUN MAVEN
echo "***** runing maven"
mvn -B -s /workspace/.m2/settings.xml -Dmaven.repo.local=/workspace/.m2 clean deploy

echo "***** step 12"

#TAG SOURCE CODE

echo "***** tagging source code"
source /workspace/version.txt
git config user.email "cloudbuild@ydeployza.com"
git config user.name "Cloud Build"
git tag -a "${VERSION}" -m "Release ${VERSION}"
git push origin "${VERSION}" --force




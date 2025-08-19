source /workspace/version.txt

git config user.email "cloudbuild@ydeployza.com"
git config user.name "Cloud Build"
git tag -a "${VERSION}" -m "Release ${VERSION}"
git push origin "${VERSION}" --force

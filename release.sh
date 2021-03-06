# Script to release to NPM and publish tag

# REMEMBER: this script is executed in the context of a travis build machine.

# remove origin remote
git remote rm origin
#git remote add origin https://SwiftDevOps:${GITHUB_TOKEN}@github.com/IBM-Swift/generator-swiftserver
git remote add origin https://nhardman:$GITHUB_TOKEN@github.com/nhardman/myrepo
VERSION=`node -e "console.log(require('./package.json').version);"`
echo "Creating release ${VERSION}"
git tag $VERSION && git push origin $VERSION || true
# Merge back into develop and push those changes
git fetch origin && git checkout develop && git merge origin/master && git push origin develop
# npm publish
makeshift $NPM_TOKEN
npm publish

# Deleting the old release branch
BRANCH_TO_DELETE=updateTo$VERSION
echo Deleting $BRANCH_TO_DELETE
curl -u nhardman:$GITHUB_TOKEN -X DELETE -H "Accept: application/vnd.github.loki-preview+json" "https://api.github.com/repos/nhardman/myrepo/branches/$BRANCH_TO_DELETE/protection"
git push origin :$BRANCH_TO_DELETE

# Script to release to NPM and publish tag

# REMEMBER: this script is executed in the context of a travis maching.

# NRH: temporary fix to set the github userid
GH_USER=nhardman
GH_REMOTE=fred

# remove origin remote
git remote rm $GH_REMOTE
#git remote add origin https://SwiftDevOps:${GH_TOKEN}@github.com/IBM-Swift/generator-swiftserver
git remote add $GH_REMOTE https://$GH_USER:$GH_TOKEN@github.com/$GH_USER/generator-swiftserver
VERSION=`node -e "console.log(require('./package.json').version);"`
echo "Creating release ${VERSION}" 
git tag $VERSION && git push $GH_REMOTE $VERSION || true
# Merge back into develop and push those changes
#git fetch $GH_REMOTE && git checkout develop && git merge $GH_REMOTE/master && git push $GH_REMOTE develop
echo "fetch"
git fetch $GH_REMOTE
echo "checkout"
git checkout develop
echo "merge"
git merge $GH_REMOTE/master
echo "push"
git push $GH_REMOTE develop
# npm publish 
echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" >> ~/.npmrc
echo "publish"
npm publish

# Deleting the old release branch
BRANCH_TO_DELETE=updateTo$VERSION
echo Deleting $BRANCH_TO_DELETE 
#curl -u SwiftDevOps:${GH_TOKEN} -X DELETE -H "Accept: application/vnd.github.loki-preview+json" "https://api.github.com/repos/IBM-Swift/generator-swiftserver/branches/$BRANCH_TO_DELETE/protection"
curl -u $GH_USER:$GH_TOKEN -X DELETE -H "Accept: application/vnd.github.loki-preview+json" "https://api.github.com/repos/$GH_USER/generator-swiftserver/branches/$BRANCH_TO_DELETE/protection"
git push $GH_REMOTE :$BRANCH_TO_DELETE


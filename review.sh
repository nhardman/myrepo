# Script to create a review branch 

# Exit if this is a merge from master
COMMIT_REGEX="Merge pull request #[0-9]+ from .+\s*Release [0-9]+\.[0-9]+\.[0-9]+"
if [[ $TRAVIS_COMMIT_MESSAGE =~ $COMMIT_REGEX ]]
then 
  echo This is a merge from master - exiting
  exit 0
fi

# We are processing a build resulting from merging a feature into develop
# Proceed to create a release branch updating the version and change log
# and a pull request from develop->master for the new release
#export GITHUB_TOKEN=$GH_TOKEN
USER=SwiftDevOps:${GITHUB_TOKEN}
USER=nhardman:${GITHUB_TOKEN}
git config user.name "Generator bot"
git config push.default simple
git remote rm origin
git remote add origin https://${USER}@github.com/nhardman/myrepo
echo Creating branch with the new version to be reviewed
git checkout -b temp
echo Updating the version
standard-version -i "CHANGES.md" --tag-version

# Delete all the other branches that are release branches
PULLS=$(curl -u ${USER} -X GET -H "Accept: application/vnd.github.loki-preview+json" "https://api.github.com/repos/nhardman/myrepo/pulls")
LENGTH=$(echo $PULLS | jq 'length')
SIZE=$(( $LENGTH - 1 ))
# Loop through all the different pull requests and delete the release branches
for i in $(seq 0 $SIZE); do
  BASE=$(echo $PULLS | jq -r ".[$i].base.ref")
  PULL_BRANCH=$(echo $PULLS | jq -r ".[$i].head.ref")
  BRANCH_REGEX="updateTo[0-9]+\.[0-9]+\.[0-9]+"
  if [[ $BASE == "master" ]] && [[ $PULL_BRANCH =~ $BRANCH_REGEX ]]; then
    # Unprotect the branch before deleting
    echo Removing protection on $PULL_BRANCH
    curl -u ${USER} -X DELETE -H "Accept: application/vnd.github.loki-preview+json" "https://api.github.com/repos/nhardman/myrepo/branches/$PULL_BRANCH/protection"
    echo Deleting $PULL_BRANCH
    git push origin :$PULL_BRANCH
  fi
done

VERSION=`node -e "console.log(require('./package.json').version);"`
BRANCH=updateTo${VERSION}
git branch -m $BRANCH
git push -u origin $BRANCH
# Protect the branch from force push and deletion
curl -u ${USER} -X PUT -H "Content-Type: application/json" -H "Accept: application/vnd.github.loki-preview+json" -d "{\"required_status_checks\": {\"strict\": true,\"contexts\": []},\"required_pull_request_reviews\":{},\"restrictions\": null,\"enforce_admins\": true}" "https://api.github.com/repos/nhardman/myrepo/branches/$BRANCH/protection"

# create a pull request to master
#curl -u ${USER} -H "Content-Type: application/json" -X POST -d "{\"title\": \"Release ${VERSION}\", \"head\": \"${BRANCH}\", \"base\": \"master\", \"body\": \"Do NOT attempt to push further changes to this branch.\"}" https://api.github.com/repos/nhardman/myrepo/pulls

#hub pull-request -b master -m "Release ${VERSION}\n\nDo NOT attempt to push further changes to this branch."
hub pull-request -b master -m "Release ${VERSION}"$'\n\nDo NOT attempt to push further changes to this branch.'
#hub pull-request -b master -m "Do NOT attempt to push further changes to this branch."

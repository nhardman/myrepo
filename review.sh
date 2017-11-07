# Script to create a review branch 

# Exit if this is a merge from master
COMMIT_REGEX="Merge pull request #[0-9]+ from .+\s*Release [0-9]+\.[0-9]+\.[0-9]+"
if [[ $TRAVIS_COMMIT_MESSAGE =~ $COMMIT_REGEX ]]
then 
  echo This is a merge from master - exiting
  exit 0
fi

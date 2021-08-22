#!/usr/bin/env bash

# Usage: ./release.sh master v1.5.3

SETUP_CFG="setup.cfg"
BASE_SOURCE_BRANCH="$1"
VERSION="$2"
OLD_VERSION=$(grep version setup.cfg | awk -F' = ' '{print $2}')
REMOTE_ORIGIN=$(grep -A3 '\[remote "origin"\]' .git/config)
if [[ $BASE_SOURCE_BRANCH != "master" ]]; then
  TARGET_BRANCH="branch-$VERSION"
else
  TARGET_BRANCH="master"
fi

if [[ $REMOTE_ORIGIN != *"github.com:RedHatQE/openshift-python-wrapper"* ]]; then
  echo "This script shouldn't run from forked repo!"
  exit 1
fi

if [[ -z "${GREN_GITHUB_TOKEN}" ]]; then
  echo "GREN_GITHUB_TOKEN is undefined"
  exit 1
fi

# Create branch for the new release
git checkout $BASE_SOURCE_BRANCH
if [[ $? ]]; then
  echo "Source branch $BASE_SOURCE_BRANCH does not exist"
  exit 1
fi

git checkout -b $TARGET_BRANCH

# Update setup.cfg with the new version and push to $TARGET_BRANCH
sed -i s/$OLD_VERSION/$VERSION/g $SETUP_CFG
git commit -a -m"Update version: $TARGET_BRANCH"
git push origin $TARGET_BRANCH

# Create release on Github
gh release create $VERSION

# Generate release notes
gren release -D prs --override

# Generate and push CHANGELOG.md
gren changelog --override
git commit -a -m"Update changelog for version $VERSION"
git push -f origin $TARGET_BRANCH

git pull origin $TARGET_BRANCH
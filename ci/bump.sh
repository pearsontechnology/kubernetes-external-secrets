#!/usr/bin/env bash

# Returns the bumped tag version
version=`git describe --tags --abbrev=0 | awk -F. '{$NF+=1; OFS="."; print $0}'`

export NEXT_VERSION=${version}

echo ${version}

git tag ${version}
git push origin --tags
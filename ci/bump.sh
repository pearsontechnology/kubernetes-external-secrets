#!/usr/bin/env bash

# Returns the bumped tag version
bump_version_tag() {
  prefix="v1.0"

  latest_tag=$(git ls-remote --tags origin | cut -f 3 -d '/' | \
    grep "^$prefix" | sort -t. -k 3,3nr | head -1)

  echo ${latest_tag}

  if [[ -z "$latest_tag" ]]; then
    tag="$prefix.0"
  else
    tag="${latest_tag%.*}.$((${latest_tag##*.}+1))"
  fi

  export IMAGE_VERSION=${tag}
  echo ${tag}
}

bump_version_tag

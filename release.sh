#!/bin/sh

set -e

ALLOW_DIRTY="true"

if [ -z "$ALLOW_DIRTY" ]; then
    if ! output=$(git status --porcelain) || ! [ -z "$output" ]; then
        git status
        echo ""
        echo "Ensure working directory is clean before releasing."
        echo ""
        exit 1
    fi
fi

SHA=$(git rev-parse --short HEAD)
_tag=`git describe --tags --abbrev=0 | awk -F. '{$NF+=1; print $0}'`
TAG=`echo ${_tag} | awk 'BEGIN {OFS="."}; {$1=$1;print $0};'`

echo "Next version is: $TAG"

perl -i -pe "s/kubernetes-external-secrets Image tag \| \`[a-zA-Z0-9\.]*/kubernetes-external-secrets Image tag \| \`$TAG/" charts/kubernetes-external-secrets/README.md
perl -i -pe "s/tag: [a-zA-Z0-9\.]*/tag: $TAG/" charts/kubernetes-external-secrets/values.yaml
perl -i -pe "s/appVersion: [a-zA-Z0-9\.]*/appVersion: $TAG/" charts/kubernetes-external-secrets/Chart.yaml
perl -i -pe "s/version: [a-zA-Z0-9\.]*/version: $TAG/" charts/kubernetes-external-secrets/Chart.yaml
(cd charts/kubernetes-external-secrets && helm init --client-only && helm package . && helm repo index --merge ../../docs/index.yaml ./ && mv *.tgz ../../docs && mv index.yaml ../../docs)

docker login ${DOCKER_USERNAME} ${DOCKER_PASSWORD}

docker build -t pearsontechnology/kubernetes-external-secrets:$SHA .
docker tag pearsontechnology/kubernetes-external-secrets:$SHA pearsontechnology/kubernetes-external-secrets:$TAG
docker tag pearsontechnology/kubernetes-external-secrets:$SHA pearsontechnology/kubernetes-external-secrets:latest

git add --all && git commit -m "chore(release): pearsontechnology/kubernetes-external-secrets:$TAG [ci skip]"
git push --follow-tags origin master && docker push pearsontechnology/kubernetes-external-secrets:$TAG && docker push pearsontechnology/kubernetes-external-secrets:latest


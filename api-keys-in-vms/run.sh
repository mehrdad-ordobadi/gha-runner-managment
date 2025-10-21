#!/bin/bash

API_KEY=$(cat "$CREDENTIALS_DIRECTORY/api_key" | tr -d '[:space:]')

REPO="ACIT3495-project2"
GH_USER="mehrdad-ordobadi"
RUNNER_NAME="mac2-runner"

if [ -n "$API_KEY" ]; then
        RESPONSE=$(curl -L -X POST \
          -H "Accept: application/vnd.github+json" \
          -H "Authorization: Bearer $API_KEY" \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          "https://api.github.com/repos/${GH_USER}/${REPO}/actions/runners/registration-token")
else
        echo "****Cant read API KEY****"
fi

REG_TOKEN=$(echo "$RESPONSE" | jq -r '.token')

if [ -z "$REG_TOKEN" ]; then
	echo "****No token!****"
fi

docker run -d --rm \
	--runtime=sysbox-runc \
	-e GITHUB_URL="https://github.com/${GH_USER}/${REPO}" \
    -e RUNNER_NAME="${RUNNER_NAME}" \
	-e RUNNER_LABELS="${RUNNER_NAME},self-hosted,linux,x64" \
    -e TOKEN=${REG_TOKEN} \
	mehrdadfordobadi/gh-runner:4
#!/bin/bash

API_KEY=$(cat "$CREDENTIALS_DIRECTORY/api_key" | tr -d '[:space:]')

if [ -n "$API_KEY" ]; then
        RESPONSE=$(curl -L -X POST \
          -H "Accept: application/vnd.github+json" \
          -H "Authorization: Bearer $API_KEY" \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          https://api.github.com/repos/mehrdad-ordobadi/ACIT3495-project2/actions/runners/registration-token)
else
        echo "****Cant read API KEY****"
fi

REG_TOKEN=$(echo "$RESPONSE" | jq -r '.token')

if [ -z "$REG_TOKEN" ]; then
	echo "****No token!****"
fi

docker run -d -e GITHUB_URL="https://github.com/mehrdad-ordobadi/ACIT3495-project2" \
        -e RUNNER_NAME="mac2-runner" \
        -e TOKEN=${REG_TOKEN} \
	mehrdadfordobadi/gh-runner:2
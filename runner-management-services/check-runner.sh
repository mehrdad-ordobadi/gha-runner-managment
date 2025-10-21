#!/bin/bash

API_KEY=$(cat "$CREDENTIALS_DIRECTORY/api_key" | tr -d '[:space:]')

REPO="ACIT3495-project2"
GH_USER="mehrdad-ordobadi"
RUNNER_NAME="mac2-runner"

remove_runner() {	
	curl -s -L \
		-X DELETE \
		-H "Accept: application/vnd.github+json" \
		-H "Authorization: Bearer $API_KEY" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		"https://api.github.com/repos/${GH_USER}/${REPO}/actions/runners/${RUNNER_ID}"
}

if [ -n "$API_KEY" ]; then
	RESPONSE=$(curl -s -L \
		-H "Accept: application/vnd.github+json" \
		-H "Authorization: Bearer $API_KEY" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		"https://api.github.com/repos/${GH_USER}/${REPO}/actions/runners" 2>/dev/null)
else
	echo "***Cannot access API key!****"
	exit 2
fi

RUNNER_STATUS=$(echo "$RESPONSE" | jq -r --arg name "$RUNNER_NAME" '.runners[] | select(.name == $name) | .status')
RUNNER_ID=$(echo "$RESPONSE" | jq -r --arg name "$RUNNER_NAME" '.runners[] | select(.name == $name) | .id')

if [ "$RUNNER_STATUS" = "online" ]; then
	exit 0
elif [ -z "$RUNNER_ID" ]; then
	echo "***Runner not found - restarting!***"
	systemctl restart runner-start.service
else
	echo "***Runner not online - removing and restarting!***"
	remove_runner
	systemctl restart runner-start.service
fi
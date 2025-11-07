#!/bin/bash

API_KEY=$(cat "$CREDENTIALS_DIRECTORY/api_key" | tr -d '[:space:]')

REPO="ACIT3495-project2"
GH_USER="mehrdad-ordobadi"
RUNNER_NAME="mac2-runner"

check_runner_status() {

if [ -n "$API_KEY" ]; then
	RESPONSE=$(curl -s -L \
		-H "Accept: application/vnd.github+json" \
		-H "Authorization: Bearer $API_KEY" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		"https://api.github.com/repos/${GH_USER}/${REPO}/actions/runners" 2>/dev/null)
else
	echo "***Cannot access API key!****" >&2
	exit 2
fi

RUNNER_STATUS=$(echo "$RESPONSE" | jq -r --arg name "$RUNNER_NAME" '.runners[] | select(.name == $name) | .status')

echo "$RUNNER_STATUS"

}

if [ -n "$API_KEY" ]; then
		echo "***Obtaining a runner registration token!***"
		RESPONSE=$(curl -L -X POST \
		-H "Accept: application/vnd.github+json" \
		-H "Authorization: Bearer $API_KEY" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		"https://api.github.com/repos/${GH_USER}/${REPO}/actions/runners/registration-token" 2>/dev/null)
else
	echo "****Cant read API_KEY!****"
	exit 1
fi

REG_TOKEN=$(echo "$RESPONSE" | jq -r '.token' 2>/dev/null)

if [ -z "$REG_TOKEN" ]; then
	echo "***No token received!***"
	exit 1
fi

echo "***Creating runner container...****"
docker run -d --rm \
	--runtime=sysbox-runc \
	-e GITHUB_URL="https://github.com/${GH_USER}/${REPO}" \
	-e RUNNER_NAME="${RUNNER_NAME}" \
	-e RUNNER_LABELS="${RUNNER_NAME},self-hosted,linux,x64" \
	-e TOKEN=${REG_TOKEN} \
	--log-driver=syslog \
	--log-opt tag="runner-container" \
	--name runner-container \
	mehrdadfordobadi/gh-runner:5

echo "***Waiting for runner to go online...***"

max_tries=30
count=0

while [ $count -lt $max_tries ]; do
	RUNNER_STATUS=$(check_runner_status)
	
	if [ "$RUNNER_STATUS" == "online" ]; then
		echo "Runner is online!"
		exit 0
	fi
	
	((count++))
	
	if [ $count -lt $max_tries ]; then
		echo "Runner pending... (attempt $count/$max_tries)"
		sleep 10
	fi
done

echo "Could not take runner online..." # Should call notify failure ideally
exit 222
#!/bin/bash

DC_WEBHOOK_URL=$(cat "$CREDENTIALS_DIRECTORY/dc-webhook-url" | tr -d '[:space:]')

REPO="ACIT3495-project2"
GH_USER="mehrdad-ordobadi"
RUNNER_NAME="mac2-runner"

MESSAGE="github repo: ${GH_USER}/${REPO} - runner: ${RUNNER_NAME}\nRunner down and can't be restored. Manual intervention required!" 

PAYLOAD=$(printf '{\n  "content": "%s"\n}' "$MESSAGE")

if [ -n "$DC_WEBHOOK_URL" ]; then
	echo "***Sending notification to the discord channel***"
	curl -H "Content-Type: application/json" \
		-X POST \
		-d "$PAYLOAD" \
		"$DC_WEBHOOK_URL"
else
	echo "****Cant read WEBHOOK URL!****"
fi

echo "Stopping restarter timer - manual intervention required!"
systemctl stop runner-restarter.timer

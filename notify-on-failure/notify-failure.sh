#!/bin/bash

DC_WEBHOOK_URL=$(cat "$CREDENTIALS_DIRECTORY/dc-webhook-url" | tr -d '[:space:]')

REPO="ACIT3495-project2"
GH_USER="mehrdad-ordobadi"
RUNNER_NAME="mac2-runner"

MESSAGE="github repo: ${GH_USER}/${REPO} - runner: ${RUNNER_NAME}\nRunner down and can't be restored!" 

PAYLOAD=$(cat <<EOF
{
  "content": "${MESSAGE}"
}
EOF
)
if [ -n "$DC_WEBHOOK_URL" ]; then
	curl -H "Content-Type: application/json" \
		-X POST \
		-d "$PAYLOAD" \
		"$DC_WEBHOOK_URL"
else
	echo "****Can\'t read WEBHOOK URL!****"
fi

echo "Stopping restarter timer - manual intervention required!"
systemctl stop runner-restarter.timer

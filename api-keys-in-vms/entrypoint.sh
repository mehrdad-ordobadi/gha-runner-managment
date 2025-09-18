#!/bin/bash

if [ -z "$TOKEN" ] || [ -z "$GITHUB_URL" ]; then
    echo "ERROR: TOKEN and GITHUB_URL environment variables are required"
    exit 1
fi

./config.sh --url "$GITHUB_URL" --token "$TOKEN" --name "$RUNNER_NAME" --labels "$RUNNER_LABELS" --replace --unattended

./run.sh
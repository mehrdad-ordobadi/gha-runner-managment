#!/bin/bash

# Shutdown handler 
cleanup() {
    echo "Received shutdown signal. Terminating processes..."
    
    # The 'docker shutdown' command is the safest way to stop the daemon
    if [ -S /var/run/docker.sock ]; then
        echo "Shutting down Docker daemon..."
        (docker shutdown &) 
    fi
    
    echo "Cleanup complete. Exiting."
    exit 0
}

# Trap the signals and call the cleanup function
trap 'cleanup' SIGTERM SIGINT

# Start dockerd, redirect logs, and run it in the background
dockerd > /var/log/dockerd.log 2>&1 &
DOCKERD_PID=$!

# Wait till docker daemon is ready
while [ ! -S /var/run/docker.sock ]; do
    sleep 1
done
echo "Docker daemon is ready."


if [ -z "$TOKEN" ] || [ -z "$GITHUB_URL" ]; then
    echo "ERROR: TOKEN and GITHUB_URL environment variables are required"
    exit 1
fi

gosu runner ./config.sh \
	--url "$GITHUB_URL" \
	--token "$TOKEN" \
	--name "$RUNNER_NAME" \
	--labels "$RUNNER_LABELS" \
	--replace \
	--unattended

exec gosu runner ./run.sh
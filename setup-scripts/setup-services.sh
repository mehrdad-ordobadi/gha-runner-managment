#!/bin/bash

# Setting up runner-starter
if ! id runner-start &>/dev/null; then
	useradd -r -s /bin/false runner-start
	usermod -aG docker runner-start
else
	echo "User: runner-starter exists and token has already been encrypted!"
	echo "Moving on..."
fi

if [ ! -e "/etc/systemd/creds/api_key" ]; then
	mkdir -p /etc/systemd/creds
	(
		read -s -r -p "Enter github PAT: " TOKEN
		echo
		echo "$TOKEN" | systemd-creds encrypt - /etc/systemd/creds/api_key
		chown runner-start:runner-start /etc/systemd/creds/api_key
		chmod 600 /etc/systemd/creds/api_key
	)
else
	echo "Github PAT has been added and encrypted!"
	echo "Moving on..."
fi

if [ ! -f /opt/runner-start/run.sh ]; then
	mkdir -p /opt/runner-start
	chown -R runner-start:runner-start /opt/runner-start
	chmod 755 /opt/runner-start
	cat <<- 'EOF' > /opt/runner-start/run.sh
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

	EOF
	chown runner-start:runner-start /opt/runner-start/run.sh
	chmod 755 /opt/runner-start/run.sh
else
	echo "Script: run.sh already exists!"
	echo "Moving one..."
fi

if [ ! -e /etc/systemd/system/runner-starter.service ]; then
	cat <<- 'EOF' > /etc/systemd/system/runner-starter.service 
		[Unit]
		Description=My Application
		After=network.target

		[Service]
		Type=oneshot
		User=runner-start
		Group=runner-start
		WorkingDirectory=/opt/runner-start
		Environment=HOME=/opt/runner-start
		ExecStart=/opt/runner-start/run.sh
		LoadCredentialEncrypted=api_key:/etc/systemd/creds/api_key

		[Install]
		WantedBy=multi-user.target
	EOF
else
	echo "systemd service file for service runner-start already exists!"
	echo "Moving one..."
fi

# Setting up runner-restarter
if [ ! -f /opt/runner-start/check-runner.sh ]; then
	cat <<- 'EOF' > /opt/runner-start/check-runner.sh
		#!/bin/bash

		API_KEY=$(cat "$CREDENTIALS_DIRECTORY/api_key" | tr -d '[:space:]')

		REPO="ACIT3495-project2"
		GH_USER="mehrdad-ordobadi"
		RUNNER_NAME="mac2-runner"

		remove_runner() {	
			echo "****Removing the offline runner...****"
			curl -s -L \
				-X DELETE \
				-H "Accept: application/vnd.github+json" \
				-H "Authorization: Bearer $API_KEY" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				"https://api.github.com/repos/${GH_USER}/${REPO}/actions/runners/${RUNNER_ID}"

			echo "****Stopping and removing the runner-container...****"
			docker stop runner-container
			docker rm -f runner-container
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
			echo "***Runner not found - attempting to create a new runner!***"
			systemctl restart runner-starter.service
		else
			echo "***Runner not online - removing!***"
			remove_runner
			echo "***Offline runner removed - attempting to create a new runner!***"
			systemctl restart runner-starter.service
		fi
	EOF
	chown runner-start:runner-start /opt/runner-start/check-runner.sh
	chmod 755 /opt/runner-start/check-runner.sh
else
	echo "Script check-runner already exists!"
	echo "Moving on..."
fi

if [ ! -f /etc/systemd/system/runner-restarter.service ]; then
	cat <<- 'EOF' > /etc/systemd/system/runner-restarter.service
		[Unit]
		Description=Monitor Runner Start Service
		After=runner-starter.service
		OnFailure=notify-failure.service

		[Service]
		Type=oneshot
		User=runner-start
		Group=runner-start
		WorkingDirectory=/opt/runner-start
		Environment=HOME=/opt/runner-start
		ExecStart=/opt/runner-start/check-runner.sh
		LoadCredentialEncrypted=api_key:/etc/systemd/creds/api_key
	EOF
else
	echo "Systemd service file for service runner-restarter already exists!"
	echo "Moving on..."
fi

if [ ! -f /etc/systemd/system/runner-restarter.timer ]; then
	cat <<- 'EOF' > /etc/systemd/system/runner-restarter.timer
		[Unit]
		Description=Monitor Runner Every 30 Minutes
		After=runner-starter.service

		[Timer]
		OnBootSec=10min
		OnActiveSec=5min
		OnUnitActiveSec=30min

		[Install]
		WantedBy=timers.target
	EOF
else
	echo "Timer file for runner-restarter service already exists!"
	echo "Moving on..."
fi

if [ ! -f /etc/polkit-1/rules.d/50-runner-start.rules ]; then
	cat <<- 'EOF' > /etc/polkit-1/rules.d/50-runner-start.rules
		polkit.addRule(function(action, subject) {
			if (action.id == "org.freedesktop.systemd1.manage-units" &&
				action.lookup("unit") == "runner-starter.service" &&
				subject.user == "runner-start" &&
				action.lookup("verb") == "restart") {
				return polkit.Result.YES;
			}
		});
	EOF
	chown root:root /etc/polkit-1/rules.d/50-runner-start.rules
	chmod 644 /etc/polkit-1/rules.d/50-runner-start.rules
else
	echo "polkit rule 50-runner-start.rules already exists!"
	echo "Moving on..."
fi

# Setting up notifier 
if [ ! -f /etc/systemd/creds/dc-webhook-url ]; then
	(
		read -s -r -p "Enter discord webhook URL: " URL
		echo
		echo "$URL" | systemd-creds encrypt - /etc/systemd/creds/dc-webhook-url
		chown runner-start:runner-start /etc/systemd/creds/dc-webhook-url
		chmod 600 /etc/systemd/creds/dc-webhook-url
	)
else
	echo "Creds for discord URL already exists and encrypted!"
	echo "Moving on..."
fi

if [ ! -f /opt/runner-start/notify-failure.sh ]; then
	cat <<- 'EOF' > /opt/runner-start/notify-failure.sh
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
	EOF
	chown runner-start:runner-start /opt/runner-start/notify-failure.sh
	chmod 755 /opt/runner-start/notify-failure.sh
else
	echo "Script: notify-failure.sh already exists!"
	echo "Moving on..."
fi

if [ ! -f /etc/systemd/system/notify-failure.service ]; then
	cat <<- 'EOF' > /etc/systemd/system/notify-failure.service
		[Unit]
		Description=Called by runner-restarter service upon failure to notify admin on discord
		After=runner-restarter.service

		[Service]
		Type=oneshot
		User=runner-start
		Group=runner-start
		WorkingDirectory=/opt/runner-start
		Environment=HOME=/opt/runner-start
		ExecStart=/opt/runner-start/notify-failure.sh
		LoadCredentialEncrypted=dc-webhook-url:/etc/systemd/creds/dc-webhook-url

		[Install]
		WantedBy=multi-user.target
	EOF
else
	echo "systemd service file for service notify-failure already exists!"
	echo "Moving on..."
fi

if [ ! -f /etc/polkit-1/rules.d/50-notify-failure.rules ]; then
	cat <<- 'EOF' > /etc/polkit-1/rules.d/50-notify-failure.rules
		polkit.addRule(function(action, subject) {
			if (action.id == "org.freedesktop.systemd1.manage-units" &&
				action.lookup("unit") == "runner-restarter.timer" &&
				subject.user == "runner-start" &&
				action.lookup("verb") == "stop") {
				return polkit.Result.YES;
			}
		});
	EOF
	chown root:root /etc/polkit-1/rules.d/50-notify-failure.rules
	chmod 644 /etc/polkit-1/rules.d/50-notify-failure.rules
else
	echo "polkit rule 50-notify-failure.rules already exists!"
	echo "Moving on..."
fi

systemctl daemon-reload

echo "Starting runner-starter service now! This may take a few minutes..."
systemctl start runner-starter.service
systemctl enable runner-starter.service

echo "Starting runner-restarter service (and timer) now!"
systemctl enable --now runner-restarter.timer

echo "*%*%*All services should be setup successfully now - use systemctl status to verify this...*%*%*"
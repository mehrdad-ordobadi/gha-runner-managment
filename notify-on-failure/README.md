# I want to a way to notify admin in case check-runner service fails. I choose Discord as the platform for notification due to lack of budget. However this can be be easily replaced by more professional platforms e.g. Slack.

## Platform:
I will use my personal discord server. I have create a channel for the notification and created a webhook.

## Methodology:
### Create the encrypted credentials:
First, as I did in **api-keys-in-vms** section I will encrypt and store the webhook URL using systemd.

```
echo "<webhook-url>>" | sudo systemd-creds encrypt - /etc/systemd/creds/dc-webhook-url

sudo chown runner-start:runner-start /etc/systemd/creds/dc-webhook-url.cred
sudo chmod 600 /etc/systemd/creds/dc-webhook-url.cred
```

### Create your script:
To reduce complexity, I will create the script in the same directory as runner-start:

```
sudo vim notify-failure.sh
sudo chown runner-start:runner-start /opt/runner-start/notify-failure.sh
sudo chmod 755 /opt/runner-start/notify-failure.sh
```

Use the script notify-failure.sh in this directory.

### Create systemd service:

We create a new service which is called by runner-restarter service upon failure.

```
# /etc/systemd/system/notify-failure.service
[Unit]
Description=Called by runner-restarter service upon failure to notify admin on discor
After=runner-restarter.service

[Service]
Type=oneshot
User=runner-start
Group=runner-start
WorkingDirectory=/opt/runner-start
Environment=HOME=/opt/runner-start
ExecStart=/opt/runner-start/notify-failure.sh
LoadCredentialEncrypted=api_key:/etc/systemd/creds/dc-webhook-url

[Install]
WantedBy=multi-user.target
```

### Allow notify-failure to stop runner-restarter.timer:
I will allow this using polkit:

```
// /etc/polkit-1/rules.d/50-notify-failure.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "runner-restarter.timer" &&
        subject.user == "runner-start" &&
        action.lookup("method") == "StopUnit") {
        return polkit.Result.YES;
    }
});
```

And give the rule proper permission:

```
sudo chown root:root /etc/polkit-1/rules.d/50-notify-failure.rules
sudo chmod 644 /etc/polkit-1/rules.d/50-notify-failure.rules
```
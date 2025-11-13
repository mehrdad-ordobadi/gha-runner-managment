# What this directory includes: 
I want to a way to notify admin in case check-runner service fails. I choose Discord as the platform for notification due to lack of budget. However this can be be easily replaced by more professional platforms e.g. Slack.

## Platform:
I will use my personal discord server. I have create a channel for the notification and created a webhook for this channel.

## Methodology:
### Create the encrypted credentials:
First, as I did in **api-keys-in-vms** section I will encrypt and store the webhook URL using systemd.

```
echo "<webhook-url>" | sudo systemd-creds encrypt - /etc/systemd/creds/dc-webhook-url

sudo chown runner-start:runner-start /etc/systemd/creds/dc-webhook-url
sudo chmod 600 /etc/systemd/creds/dc-webhook-url
```

### Create your script:
To reduce complexity, I will create the script in the same directory as runner-start:

```
# Create /opt/runner-start/notify-failure.sh with content available in this directory on the repository
sudo chown runner-start:runner-start /opt/runner-start/notify-failure.sh
sudo chmod 755 /opt/runner-start/notify-failure.sh
```

### Create systemd service:

We create a new service which is called by runner-restarter service upon failure. ```/etc/systemd/system/notify-failure.service ``` should contain the same content as present on the same directory on this repository.

### Allow notify-failure to stop runner-restarter.timer:
I will allow this using polkit:


Create ```/etc/polkit-1/rules.d/50-notify-failure.rules``` as it is present in this directory on the repository.

And give the rule proper permission:

```
sudo chown root:root /etc/polkit-1/rules.d/50-notify-failure.rules
sudo chmod 644 /etc/polkit-1/rules.d/50-notify-failure.rules
```

**Note:** There is no need to enable and start this service as it is called by another service.
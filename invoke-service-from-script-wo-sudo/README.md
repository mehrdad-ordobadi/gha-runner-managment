# Provide limited privileges to a script without giving it sudo:

In order to restart (manage) a system service using a script, the script requires sudo privilege. This is a security vulnerability. In order to address this we will use Polkit (PolicyKit) tool, which allowed privileged processes to grant temporary, specific permissions to a unprivileged processes.

## Case:

We have a system service being run as User: runner-start - which starts a github actions runner container. We need to create a repeating mechanism that monitors this runner and if deleted, restart the service to create a new runner.

## Solution:

We create a service that runs a script to check runner, and if failed invoke runner-start. This service is run by the same user as runner-start service, since it needs access to the same credentials. We can this service runner-restarter.

```
# /etc/systemd/system/runner-restarter.service
[Unit]
Description=Monitor Runner Start Service
After=runner-start.service

[Service]
Type=oneshot
User=runner-start
Group=runner-start
WorkingDirectory=/opt/runner-start
Environment=HOME=/opt/runner-start
ExecStart=/opt/runner-start/check-runner.sh
LoadCredentialEncrypted=api_key:/etc/systemd/creds/api_key
```

Next we create a timer service to run this service periodically:

```
# /etc/systemd/system/runner-restarter.timer
[Unit]
Description=Monitor Runner Every 5 Minutes
After=runner-start.service
Requires=runner-start.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

We setup polkit to allow runner-start to get sudo-like privilege **if action is of managing systemd and the service being managed is runner-starter, and action is start**. i.e. if the action is related to managing some systemd (starting, stopping, restarting, or reloading them), and the action is start, then use runner-start user can do it without sudo.

```
// /etc/polkit-1/rules.d/50-runner-start.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "runner-start.service" &&
        subject.user == "runner-start" &&
        action.lookup("method") == "StartUnit") {
        return polkit.Result.YES;
    }
});
```



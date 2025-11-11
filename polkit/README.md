# Provide limited privileges to a script without giving it sudo:

In order to restart (manage) a system service using a script, the script requires sudo privilege. This is a security vulnerability. In order to address this we will use Polkit (PolicyKit) tool, which allowed privileged processes to grant temporary, specific permissions to a unprivileged processes.

## Case:

We have a system service being run as User: runner-start - which starts a github actions runner container. We need to create a repeating mechanism that monitors this runner and if deleted, restart the service to create a new runner.

## Solution:

We create a service that runs a script to check runner, and if failed invoke runner-start. This service is run by the same user as runner-start service, since it needs access to the same credentials. We call this service runner-restarter.

Create the file ```/etc/systemd/system/runner-restarter.service``` with content the same as present in the same directory on this repository.


Next we create a timer service to run this service periodically. The timer configuration is set at ```/etc/systemd/system/runner-restarter.timer``` with content as present in the same directory on this repository.


We setup polkit to allow runner-start to get sudo-like privilege **if action is of managing systemd and the service being managed is runner-starter, and action is start**. i.e. if the action is related to managing some systemd (starting, stopping, restarting, or reloading them), and the action is start, then use runner-start user can do it without sudo. You need to make sure polkit is setup on your server.

Create the fill ```/etc/polkit-1/rules.d/50-runner-start.rules``` with content as present in the same directory on this repository.

### Note:
The Polkit rule file must have the correct permissions, or Polkit will ignore it.

```
sudo chown root:root /etc/polkit-1/rules.d/50-runner-start.rules
sudo chmod 644 /etc/polkit-1/rules.d/50-runner-start.rules
```

Once all the files are created and have the proper permission, you can start the timer:

```
systemctl enable --now runner-restarter.timer
```

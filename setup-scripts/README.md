# What this directory includes:
In order to setup the system developed in this repository quickly, I have created two bash scripts to do all the work.

## Instructions:

1. Create/copy the scripts on the server at the directory ```/opt/setup-server/```.

2. Run ```/opt/setup-server/setup-dependencies.sh``` with sudo.

3. Run ```/opt/setup-server/setup-services.sh``` with sudo.

**Note:** Ideally this task should be done using a configuration management tool like ansible. But at this point, this is out of the scope of this homelab project.
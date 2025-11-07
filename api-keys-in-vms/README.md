This mini-project documents experiments how to store an api key on a VM safely and provide automated access.
Methodology:

##  Storing API key:

### Before anything: note that you should encrypt your disk during ubuntu installation.

### Create the encrypted credentials:

```
# Create runner-start user
sudo useradd -r -s /bin/false runner-start

# Create cred directory
sudo mkdir -p /etc/systemd/creds

echo "<your_api_key>" | sudo systemd-creds encrypt - /etc/systemd/creds/api_key

# Set appropriate permissions
sudo chown runner-start:runner-start /etc/systemd/creds/api_key
sudo chmod 600 /etc/systemd/creds/api_key
```

#### Create your script

```
# Create application directory
sudo mkdir -p /opt/runner-start

# Change ownership to runner-start user
sudo chown -R runner-start:runner-start /opt/runner-start

# Set appropriate permissions
sudo chmod 755 /opt/runner-start  # Directory readable/executable

# Copy your script to the directory
sudo cp your_script.sh /opt/runner-start/run.sh

# Make runner-start the owner
sudo chown runner-start:runner-start /opt/runner-start/run.sh

# Make script executable
sudo chmod 755 /opt/runner-start/run.sh
```

### Create systemd service:

create the service config file:

```
sudo vim /etc/systemd/system/runner-start.service
```

with content:

```
cat /etc/systemd/system/runner-start.service
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
```

#### Note for docker only solution: 

If you want to only provide access to docker use this instead:

```
# In your service file
ExecStart=/usr/bin/docker run --rm \
  -v $CREDENTIALS_DIRECTORY/api_key:/run/secrets/api_key:ro \
  your_image

# In your container, read from /run/secrets/api_key
```



### Heres the file structure of the this example:

            /opt/runner-start/
                    ├── run.sh          (owner: runner-start:runner-start, permissions: 755)
                    ├── main.py         (owner: runner-start:runner-start, permissions: 644)
                    └── config/
                        └── app.conf    (owner: runner-start:runner-start, permissions: 644)

            /etc/systemd/creds/
                            └── api_key    (owner: runner-start:runner-start, permissions: 600)sy

### Enable the sevice:

```
# Reload systemd configuration
sudo systemctl daemon-reload

# Enable and start your service
sudo systemctl enable runner-start.service
sudo systemctl start runner-start.service

# Check status
sudo systemctl status runner-start.service
```

## Accessing the API key:

example of use:

```
#!/bin/bash
# /opt/runner-start/run.sh (absolute path to the script)

# The credential is available at $CREDENTIALS_DIRECTORY/api_key
API_KEY=$(cat "$CREDENTIALS_DIRECTORY/api_key")

# Use the API key in your application
curl -H "Authorization: Bearer $API_KEY" https://api.example.com/data

# Or export it for other processes
export API_KEY
python3 /opt/runner-start/main.py
```
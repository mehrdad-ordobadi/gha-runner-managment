This mini-project documents experiments how to store an api key on a VM safely and provide automated access.
Methodology:

##  Storing API key:

### Before anything: note that you should encrypt your disk during ubuntu installation.

### Create the encrypted credentials:

```
# Create myapp user
sudo useradd -r -s /bin/false myapp

# Create cred directory
sudo mkdir -p /etc/systemd/creds

# Create the credential (you'll be prompted for the actual API key)
echo "your_actual_api_key_here" | sudo systemd-creds encrypt --name=api_key - /etc/systemd/creds/api_key.cred

# Set appropriate permissions
sudo chown myapp:myapp /etc/systemd/creds/api_key.cred
sudo chmod 600 /etc/systemd/creds/api_key.cred
```

#### Create your script

```
# Create application directory
sudo mkdir -p /opt/myapp

# Change ownership to myapp user
sudo chown -R myapp:myapp /opt/myapp

# Set appropriate permissions
sudo chmod 755 /opt/myapp  # Directory readable/executable

# Copy your script to the directory
sudo cp your_script.sh /opt/myapp/run.sh

# Make myapp the owner
sudo chown myapp:myapp /opt/myapp/run.sh

# Make script executable
sudo chmod 755 /opt/myapp/run.sh
```

### Create systemd service:

create the service config file:

```
sudo vim /etc/systemd/system/myapp.service
```

with content:

```
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=myapp # change this
Group=myapp # change this
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/run.sh # location of the script that will use the credentials
LoadCredential=api_key:/etc/systemd/creds/api_key.cred 
Restart=on-failure

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

/opt/myapp/
        ├── run.sh          (owner: myapp:myapp, permissions: 755)
        ├── main.py         (owner: myapp:myapp, permissions: 644)
        └── config/
            └── app.conf    (owner: myapp:myapp, permissions: 644)

/etc/systemd/creds/
                └── api_key.cred    (owner: myapp:myapp, permissions: 600)sy

### Enable the sevice:

```
# Reload systemd configuration
sudo systemctl daemon-reload

# Enable and start your service
sudo systemctl enable myapp.service
sudo systemctl start myapp.service

# Check status
sudo systemctl status myapp.service
```

## Accessing the API key:

example of use:

```
#!/bin/bash
# /opt/myapp/run.sh (absolute path to the script)

# The credential is available at $CREDENTIALS_DIRECTORY/api_key
API_KEY=$(cat "$CREDENTIALS_DIRECTORY/api_key")

# Use the API key in your application
curl -H "Authorization: Bearer $API_KEY" https://api.example.com/data

# Or export it for other processes
export API_KEY
python3 /opt/myapp/main.py
```


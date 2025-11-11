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
sudo chmod 755 /opt/runner-start

# Copy/create tehs script run.sh as it is available in the same directory on this repo.

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

with content as runner-start.service in the same directory on this repository.

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
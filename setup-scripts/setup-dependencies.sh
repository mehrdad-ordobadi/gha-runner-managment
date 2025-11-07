#!/bin/bash

echo -e "*=*=*Installing basic dependencies*=*=*"
apt update
apt install ca-certificates curl jq wget -y

# Check for existing docker versions and uninstall them
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove $pkg; done

# Install docker
echo "*=*=*Begin docker installation*=*=*"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update

echo "*=*=*Install docker services*=*=*"
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# this part is not really needed in a real server since runner container will be run by a different user
echo "*=*=*Add user to docker group*=*=*"
groupadd docker 2>/dev/null || true

# Running this script with sudo so need $SUDO_USER
usermod -aG docker $SUDO_USER 

# Now install sysbox:
echo "*=*=*Install sysbox*=*=*"
wget https://downloads.nestybox.com/sysbox/releases/v0.6.7/sysbox-ce_0.6.7-0.linux_amd64.deb
echo "b7ac389e5a19592cadf16e0ca30e40919516128f6e1b7f99e1cb4ff64554172e  sysbox-ce_0.6.7-0.linux_amd64.deb" | sha256sum -c

apt install ./sysbox-ce_0.6.7-0.linux_amd64.deb -y

# Install kernel headers
apt install -y linux-headers-$(uname -r)

rm -f sysbox-ce_0.6.7-0.linux_amd64.deb

# Install polkit daemon
apt install polkitd -y
sudo systemctl start polkit

echo "*=*=*Dependency installation done!*=*=*"
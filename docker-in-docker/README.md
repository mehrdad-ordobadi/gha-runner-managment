# Isolation in Docker containers

In order to provide docker containers with more isolation to harden security for tasks like running docker on docker (DinD) we need to use alternative docker runtime tools that provide this isolation (eliminating the need to run containers as --privileged) and enable containers to run the same workload a VM can.

There are several options:
* Kata
* Kubevirt
* Sysbox

## Kata and Kubevirt:
They create and run virtual machines below containers - i.e.:
* VM-based isolation: Each container gets its own kernel running in a minimal VM (using hypervisors like QEMU/KVM or Firecracker)
* Hardware virtualization: Leverages CPU virtualization extensions (Intel VT-x, AMD-V) to provide strong isolation boundaries
* Guest kernel: The containerized workload runs on a separate guest kernel, not the host kernel
* Performance optimization: Uses stripped-down VMs with fast boot times (milliseconds) and minimal memory overhead through techniques like VM templating and memory deduplication

### pros:
* Strong security isolation
* True multi-tenancy
* Kernel Independence
* Compliance Friendly

### cons:
* Higher resource consumption (~100-200MB per container + cpu)
* Slower startup times
* Limited host integration
* More complexity

## Sysbox:
Sysbox does not run containers on separate VMs. enhances standard Linux containers to run system-level workloads securely without requiring privileged access. i.e.:
* Kernel namespace improvements: Extends Docker's namespace isolation by virtualizing portions of /proc and /sys filesystems per container
* User namespace mapping: Automatically uses user namespaces to map root inside containers to unprivileged users on the host
* Systemd support: Allows running systemd and other system services inside containers without --privileged flag
* Nested containerization: Enables running Docker or Kubernetes inside containers safely by presenting virtualized system resources

### pros:
* Native container performance - No VM overhead, near-zero performance penalty
* Enhanced capabilities: Run systemd, Docker-in-Docker, and system workloads without privileged mode
* Standard container density and startup speed
* simpler architecture

### cons:
* Weaker isolation
* Requires specific kernel features and versions (Linux 5.x+) - you can check kernel version using ``` uname -r ````
* Smaller community and ecosystem
* Not true multi-tenancy


For our purpose - since we are only interested in DinD, and since there are resource constraints, we will use Sysbox, which is designed for the purpose of DinD.

## Sysbox installation on Ubuntu:

### First remember you need docker installed:

```
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Installation using apt package manager:

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Now install the latest version:
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Verify docker service is on:
sudo systemctl status docker

# If it's not:
sudo systemctl start docker

# Finally run to run docker without sudo:
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
exit
docker ps
```

### Now to install Sysbox

```
# First download the package:
wget https://downloads.nestybox.com/sysbox/releases/v0.6.7/sysbox-ce_0.6.7-0.linux_amd64.deb

# or if arm: 
# wget https://downloads.nestybox.com/sysbox/releases/v0.6.7/sysbox-ce_0.6.7-0.linux_arm64.deb

# Verify checksum:

echo "b7ac389e5a19592cadf16e0ca30e40919516128f6e1b7f99e1cb4ff64554172e  sysbox-ce_0.6.7-0.linux_amd64.deb" | sha256sum -c

# or for arm:
# echo "16d80123ba53058cf90f5a68686e297621ea97942602682e34b3352783908f91  sysbox-ce_0.6.7-0.linux_arm64.deb" | sha256sum -c

# Stop and remove all docker containers - recommended - returns exit code 1 if there are none:
docker rm $(docker ps -a -q) -f

# Make sure jq is installed:
sudo apt-get install jq -y

# And the run:
sudo apt install sysbox-ce_0.6.7-0.linux_amd64.deb -y

# or for arm:
# sudo apt install sysbox-ce_0.6.7-0.linux_arm64.deb -y

# And verify it is running:
sudo systemctl status sysbox -n20
```

## Running DinD:
Sysbox makes running d-in-d very simple, you simply need to use sysbox and that's it! As a demostration, we have created the following container:

```
FROM ubuntu:latest

RUN apt update && apt install --no-install-recommends -y \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common 

RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc

RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt install --no-install-recommends -y \
    docker-ce \
    docker-ce-cli \
    docker-buildx-plugin \
    containerd.io

# Create startup script
RUN echo '#!/bin/bash\n\
    dockerd > /var/log/dockerd.log 2>&1 &\n\
    sleep 5\n\
    exec "$@"' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
```

The above container simply installs docker inside the container and keeps the it running. Next we build and run the container:

```
docker build -t testing-dind:1 .

# run the container with an interactive shell:
docker run --rm -it --runtime=sysbox-runc testing-dind:1
docker ps
```

In order to test your DinD isolation, inside your container:
```
docker run -d nginx
docker ps
```

While the nginx container is running in your container, separately, on your host, run:

```
docker ps 
```

You should not be able to see the nested nginx container from your host! Excellent!

Moreover, we can check for storage isolation - run this command inside the container:

```
cat /proc/self/mountinfo | grep "/var/lib/docker"
```

You should be able to see this in the output:

```
/var/lib/sysbox/docker/<container-id> /var/lib/docker
```

This shows that sysbox has create isolated storage and the docker inside your container can't access and temper your host data.

You can also check to make sure your container is not running in privileged mode:

```
docker inspect <your-sysbox-container-id> | grep -i privileged

# You should see "Privileged": false,
```

Excellent! You are now running DinD safely and in isolation using sysbox!

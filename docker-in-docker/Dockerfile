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
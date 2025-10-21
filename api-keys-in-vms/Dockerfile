# Use a lean base image suitable for the runner
FROM ubuntu:24.04

# Define build arguments and environment variables
ARG RUNNER_VERSION="2.328.0"
ENV GITHUB_RUNNER_VERSION=${RUNNER_VERSION}
ENV GITHUB_URL=""
ENV RUNNER_NAME=""
ENV TOKEN=""
ENV RUNNER_LABELS=""

# Install required packages without sudo, unnecessary tools like nodejs, npm, or docker
RUN apt update && apt install --no-install-recommends -y \
    ca-certificates \
    curl \
    gnupg-agent \
    bash \
    git \
    tar \
    gosu \
    dumb-init \
    gzip \
    nodejs \
    npm \
    && rm -rf /var/cache/apt/*

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

# Create a non-root user and set permissions
RUN groupadd -r runner && \
    useradd -r -u 1001 -g runner runner && \
    usermod -aG docker runner

# Set the working directory for the runner
WORKDIR /home/runner/actions-runner


# Download and extract the runner, verifying the checksum
RUN curl -o actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz -L \
"https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" && \
echo "01066fad3a2893e63e6ca880ae3a1fad5bf9329d60e77ee15f2b97c148c3cd4e actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" | sha256sum -c && \
tar xzf actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz && \
rm actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz

COPY entrypoint.sh .
RUN chown runner:runner entrypoint.sh && chmod +x entrypoint.sh

# In order to run docker daemon in entrypoint.sh we need root - will de-privilege after
USER root 

# Use dumb-init as the he container's PID 1
ENTRYPOINT ["/usr/bin/dumb-init", "--", "./entrypoint.sh"]
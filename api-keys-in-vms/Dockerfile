# Use a lean base image suitable for the runner
FROM ubuntu:24.04

# Define build arguments and environment variables
ARG RUNNER_VERSION="2.328.0"
ENV GITHUB_RUNNER_VERSION=${RUNNER_VERSION}
ENV GITHUB_URL=""
ENV RUNNER_NAME=""
ENV TOKEN=""

# Install required packages without sudo, unnecessary tools like nodejs, npm, or docker
RUN apt update && apt install -y \
    curl \
    bash \
    git \
    tar \
    gzip \
    nodejs \
    npm \
    docker.io \
    ca-certificates \
    && rm -rf /var/cache/apt/*

# Create a non-root user and set permissions
RUN groupadd -r runner && \
    useradd -r -u 1001 -g runner runner

# Set the working directory for the runner
WORKDIR /home/runner/actions-runner

COPY entrypoint.sh .

RUN chown runner:runner entrypoint.sh && chmod +x entrypoint.sh

# Download and extract the runner, verifying the checksum
RUN curl -o actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz -L \
    "https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" && \
    echo "01066fad3a2893e63e6ca880ae3a1fad5bf9329d60e77ee15f2b97c148c3cd4e actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" | sha256sum -c && \
    tar xzf actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz && \
    rm actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz

USER runner

ENTRYPOINT ["./entrypoint.sh"]
# Setting up a containerized self-hosted Github Actions runner on a homelab setup

## Description:

In order to facilitate other homelab projects while eliminating any infrastructure or subscription cost, I have setup a containerized self-hosted GHA runner on a old laptop I have available at home.

I have setup a Debian 13.1 (trixie) VM on an old macbook pro with Mac OS Monterey as the underlying host OS. The VM is provisioned using UTM (QEMU engine) - unfortunately VMWare Fusion is not supported on Mac OS Monterey and newer versions of Mac OS do not support the hardware on this old lapto (this is a security concern!).

The runner is containerized to provide an extra level of the security, potability and most importantly immutability.

## Goals:
1. Facilitate other project by having a free, self-hosted runner available.

2. Familiarize myself with security best-practices regarding this setup.

## Repository structure:
As you browse through this structure you may notice about the odd file structure present. This is dude to the fact that as I worked to develop this system, I had to research security best practices for separate issues, and I wanted to document my thought process and knowledge for future use.

Therefore, there are different directories for different aspects of the system. However for a finalized product, you can see the scripts available at ```setup-scripts``` directory. The scripts put everything together and setup the system quickly.


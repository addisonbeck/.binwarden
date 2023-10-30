# Bitwarden Environment Setup 🚀

This is an *experimental* project aimed at building an easy to use installer for a full Bitwarden development environement. Currently Ubuntu is supported, with plans to support at least MacOs soon.

This tool installs the bare minimum software for building and working with Bitwarden repositories, but can be supplemented with additional scripts for installing common but not required tools.

## Features

* 🔏 GPG key creation & signing for commits staight out of the box. No setup required.
* 🌐 Remote dev environment friendly. Secure your code off-machine and access it over ssh and the web.
* ⚡ Intensely fast development environment setup. Cut the first week out of onboarding!
* 🤝 Totally extendible. Bring your own secondary scripts, or share them with the team.

## Instructions

1. To begin: ensure you have a clean machine. So far this has only been tested as a fresh Ubuntu 22.04 droplet on Digital Ocean.
1. To configure: Open [this configuration template vault item](https://vault.bitwarden.com/#/vault?organizationId=4e5d875e-e6a1-4c3a-a053-a9dc01180a42&itemId=898ec3f8-14ca-4354-b2f3-b0b2014f12fa). It is a configuration template. Follow the instructions written in the note of the template.
1. To start the installer: open a terminal on the machine you are configuring and run the following command:
    ```bash
    mkdir environment-setup && \
    cd environment-setup && \
    curl -s https://raw.githubusercontent.com/addisonbeck/environment-setup/main/main.sh \
    --output main.sh && \
    bash main.sh
    ```
1. You will be asked to authenticate with the Bitwarden CLI to pull information from your "bitwarden-environment-setup" vault item.
1. Once the installer is complete: run any supplementary scripts you would like, and reboot the machine before using.

# Bitwarden Environment Setup 🚀

This is an *experimental* project aimed at building an easy to use installer for a full Bitwarden development environement. Currently Ubuntu is supported, with plans to support at least MacOs soon.

This tool installs the bare minimum software for building and working with Bitwarden repositories, but can be supplemented with additional scripts for installing common but not required tools.

## Features

* 🔏 GPG key creation & signing for commits staight out of the box. No setup required.
* 🌐 Remote dev environment friendly. Secure your code off-machine and access it over ssh and the web.
* ⚡ Intensely fast development environment setup. Cut the first week out of onboarding!
* 🤝 Totally extendible. Bring your own secondary scripts, or share them with the team.

## Instructions

To configure: Open [this configuration template vault item](https://vault.bitwarden.com/#/vault?organizationId=4e5d875e-e6a1-4c3a-a053-a9dc01180a42&itemId=898ec3f8-14ca-4354-b2f3-b0b2014f12fa). It is a configuration template. Follow the instructions written in the note of the template.

To build a user and install from root on a fresh machine:

```bash
curl -s https://raw.githubusercontent.com/addisonbeck/environment-setup/dev/bin/provision-machine \
--output main.sh && \
bash main.sh
```

To install on an existing machine:

```bash
cd ~ &&
git init &&
git remote add origin https://github.com/addisonbeck/environment-builder.git &&
git fetch &&
git checkout -f dev
```

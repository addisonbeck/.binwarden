#!/bin/bash

REPOPATH=https://raw.githubusercontent.com/addisonbeck/environment-setup/main
OSCONFIGPATH=$REPOPATH/os-configs
DEVCONFIGPATH=$REPOPATH/dev-configs

install_self () {
  echo "Downloading the builder tools"
  curl -s https://raw.githubusercontent.com/addisonbeck/environment-setup/main/lib/formatters.sh --output formatters.sh
  source formatters.sh
}

determine_os () {
  h2 "Determining OS"
  KERNEL=$(uname -s)
  case "$KERNEL" in
   "Linux")
     PLATFORM="linux"
    ;;
   *)
     PLATFORM="macos"
    ;;
  esac
}

prepare_linux () {
  h2 "Preparing linux"
  h3 "Removing needrestart, we're going to reboot at the end of all this"
  sudo apt-get -qq remove needrestart
  h3 "Installing unzip"
  sudo apt-get -qq install unzip
}

prepare_os () {
  h2 "Doing some initial OS config work before we really get started"
  case "$PLATFORM" in
   "linux")
      prepare_linux
    ;;
   *)
     :
    ;;
  esac
}

download_bw () {
  h2 "Downloading bw for $PLATFORM"
  curl -s --location "https://vault.bitwarden.com/download/?app=cli&platform=$PLATFORM" --output bw.zip
  h3 "Extracting bw executable"
  unzip bw.zip -d . 
  h3 "Adding execute permissions to the bw executable"
  chmod +x bw
}

login_bw () {
  h2 "Logging in to bw"
  BW_SESSION="$(./bw login --raw)"
  success "Successfully logged in to Bitwarden. Session key: $BW_SESSION"
}

find_config_in_vault () {
  h2 "Looking for a \"bitwarden-environment-setup\" login"
  BW_CONFIG=$(./bw list items --search "bitwarden-environment-setup" --collectionid 'null' --session $BW_SESSION)
}

parse_config_item () {
  echo $BW_CONFIG | python3 -c "import sys, json; print(json.load(sys.stdin)[0]${1})"
}

parse_config_item_custom_field () {
  echo $BW_CONFIG | python3 -c "import sys, json; print(next(cf for cf in json.load(sys.stdin)[0]['fields'] if cf['name'] == '${1}')['value'])"
}

parse_config () {
  h2 "Extracting values and files from config"
  OSUSERNAME=$(parse_config_item_custom_field "system-username")
  OS=$(parse_config_item_custom_field "system-os")
  PROJECTSFOLDERNAME=$(parse_config_item_custom_field "projects-folder-name")
  GITFULLNAME=$(parse_config_item_custom_field "git-full-name")
  EMAIL=$(parse_config_item "['login']['username']")
  GITHUBPAT=$(parse_config_item_custom_field "github-pat")
  INSTALLATIONID=$(parse_config_item_custom_field "installation-id")
  INSTALLATIONKEY=$(parse_config_item_custom_field "installation-key")
  ./bw get attachment secrets-for-env-setup.json --itemid d4195f67-dd43-4465-84d7-ae320013e6ff --session $BW_SESSION
  sudo mv secrets-for-env-setup.json secrets.json
  ./bw get attachment additional-keys-for-cloud-services.json --itemid d4195f67-dd43-4465-84d7-ae320013e6ff --session $BW_SESSION
  DATABASEPASSWORD=$(./bw generate --passphrase --words 3 -c --includeNumber --separator - --session $BW_SESSION)
}

configure_ubuntu () {
  h2 "Downloading and installing licensing certs"
  LICENSINGCERTPW=$(./bw get password 7123e5d3-f837-4a8c-810a-a7ca00fe1fdd --session $BW_SESSION)
  ./bw get attachment dev.cer --itemid 7123e5d3-f837-4a8c-810a-a7ca00fe1fdd --session $BW_SESSION
  ./bw get attachment dev.pfx --itemid 7123e5d3-f837-4a8c-810a-a7ca00fe1fdd --session $BW_SESSION

  sudo openssl x509 -inform DER -in dev.cer -out dev.crt
  sudo mv dev.crt /usr/local/share/ca-certificates/
  sudo chmod 644 /usr/local/share/ca-certificates/dev.crt

  sudo update-ca-certificates

  h2 "Using root user to setup an user account for '$OSUSERNAME'"
  curl -s $OSCONFIGPATH/ubuntu/configure-user.sh --output configure-user.sh
  source configure-user.sh

  h2 "Running the rest of the process as $OSUSERNAME"
  su -s /bin/bash -c "curl -s $OSCONFIGPATH/ubuntu/configure-dev-environment.sh --output configure-dev-environment.sh" -l $OSUSERNAME
  su -s /bin/bash -c "curl -s $OSCONFIGPATH/ubuntu/startup.sh --output startup.sh" -l $OSUSERNAME
  su -s /bin/bash -c "bash configure-dev-environment.sh '$OSUSERNAME' '$PROJECTSFOLDERNAME' '$GITFULLNAME' '$EMAIL' '$GITHUBPAT' '$INSTALLATIONID' '$INSTALLATIONKEY' '$LICENSINGCERTPW' '$DATABASEPASSWORD'" -l $OSUSERNAME
}

configure_environment () {
  h2 "Configuring dev environment"
  case "$OS" in
    # When adding new operating systems this function should ensure that:
    # 1. A user account is set up with a directory and sudo access
    # 2. Ssh login is configured
    # 5. Git is installed and configured
    # 6. The Github CLI is installed and authenticated against
    # 7. Docker is installed
    # 8. Nvm is install and running the latest LTS of node
   "ubuntu")
      configure_ubuntu
    ;;
   *)
     :
    ;;
  esac
}

install_self

h1 "Building environment"

determine_os
prepare_os
download_bw
login_bw
find_config_in_vault
parse_config
configure_environment

#!/bin/bash

OSUSERNAME=$1
PROJECTSFOLDERNAME=$2
GITFULLNAME=$3
EMAIL=$4
GITHUBPAT=$5
INSTALLATIONID=$6
INSTALLATIONKEY=$7
LICENSEPW=$8
DBPASSWORD=$9

source /home/$OSUSERNAME/environment-setup/formatters.sh

cd /home/$OSUSERNAME
export DEBIAN_FRONTEND=noninteractive

install_package () {
  sudo apt-get -qq -o "DPkg::Lock::Timeout=180" install $1 > /dev/null
}

update_packages () {
  sudo apt-get -qq -o "DPkg::Lock::Timeout=180" update > /dev/null
}

upgrade_packages () {
  sudo -E apt-get -qq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" -o "DPkg::Lock::Timeout=180" upgrade > /dev/null
}

h2 "Setting up a dev environment"

install_git () {
  h3 "Installing git"
  install_package "git"
  h3 "Configuring git"
  git config --global user.name $GITFULLNAME
  git config --global user.email $EMAIL
  h3 "Setting the default branch name"
  git config --global init.defaultBranch main
}

install_gh () {
  h3 "Installing the Github CLI"
  install_package "gh"
  h3 "Saving your Github PAT as an environment variable"
  echo "export GH_TOKEN=$GITHUBPAT" >> /home/$OSUSERNAME/.bash_profile
  h3 "Reloading your bash profile"
  source /home/$OSUSERNAME/.bash_profile
}

install_docker () {
  h3 "Getting ready to install Docker"

  h3 "Creating a docker group and adding us to it"
  sudo addgroup docker
  sudo usermod -aG docker $OSUSERNAME

  echo "Installing Docker"
  install_package "apt-transport-https ca-certificates curl software-properties-common"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
  update_packages
  install_package "docker-ce"
}

setup_commit_signing () {
  h3 "Setting up commit signing"

  h3 "Installing gnupg"
  install_package "gnup"

  h3 "Building a gpg key"
  PASSPHRASE=$(openssl rand -base64 12)
  gpg --batch --gen-key <<EOF
Key-Type: default
Subkey-Type: default
Name-Real: $GITFULLNAME
Name-Comment: Autogenerated by the Bitwarden Environment Builder
Name-Email: $EMAIL
Passphrase: $PASSPHRASE
Expire-Date: 0
%commit
EOF
 gpg --output public.pgp --armor --export $EMAIL
 h3 "Uploading the new gpg key to Github"
 gh gpg-key add public.pgp
 h3 "Setting the new gpg key as your global signing key in git"
 GPG_ID=$(gpg --list-packets <public.pgp | awk '$1=="keyid:"{print$2}' | awk 'FNR <= 1')
 git config --global user.signingkey $GPG_ID
 git config --global commit.gpgsign true
}

update_all_packages () {
  h3 "Updating & upgrading packages"
  update_packages
  # We are telling upgrade very very loudly not to ask for any user input
  upgrade_packages
}

# This function registers the official microsoft repo as the source for MS packages on the machine
# Ubuntu's repo is the default, but it is missing up to date versions of many packages
# MS advises folks to use the MS repo in several places on MSDN, including here: 
# https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.3#installation-via-package-repository-the-package-repository
register_microsoft_repo () {
  h3 "Connecting to the Microsoft package repo"
  update_packages
  install_package "wget apt-transport-https software-properties-common"
  source /etc/os-release
  wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  h3 "Setting the priority of the Microsoft repo to high"
  sudo touch /etc/apt/preferences
  echo -e "Package: * \nPin: origin \"packages.microsoft.com\" \nPin-Priority: 1001" | sudo tee -a /etc/apt/preferences > /dev/null
  h3 "Deleting install file"
  rm packages-microsoft-prod.deb
  h3 "Updating packages"
  update_packages
}

install_powershell () {
  h3 "Installing Powershell"
  install_package "powershell"
}

install_dotnet_sdk () {
  h3 "Installing Dotnet 6"
  install_package "dotnet-sdk-6.0"
}

setup_bitwarden_server () {
  h3 "Setting up the bitwarden server"
  # Clone the repo
  
  h3 "Cloning the repo"
  cd /home/$OSUSERNAME/$PROJECTSFOLDERNAME
  gh repo clone bitwarden/server
  cd server 

  h3 "Configuring the git blame"
  git config blame.ignoreRevsFile .git-blame-ignore-revs

  # NOTE: This is optional in the contributing guide, and maybe should be an option here as well.
  h3 "Setting up a pre-commit hook to run dotnet format"
  git config --local core.hooksPath .git-hooks

  cd dev
  h3 "Cloning a .env file from the template"
  sudo cp .env.example .env
  h3 "Generating a database password"
  h3 "Setting the database password in .env"
  sudo sed -i "s/SET_A_PASSWORD_HERE_123/$DBPASSWORD/g" .env

  h3 "Running docker compose"
  sudo docker compose --profile cloud --profile mail up -d

  h3 "Installing the Azurite tools"
  sudo pwsh -Command "Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force"
  sudo pwsh setup_azurite.ps1

  h3 "Runnining migrations scripts"
  sudo pwsh migrate.ps1

  h3 "Creating Identity and Data Protection licenses"
  sudo ./create_certificates_linux.sh > fingerprints.txt
  sudo mv data_protection_dev.crt /usr/local/share/ca-certificates/
  sudo mv identity_server_dev.crt /usr/local/share/ca-certificates/
  sudo update-ca-certificates

  h3 "Adding the pfx license to dotnet's source folder"
  pwsh -Command "using namespace System.Security.Cryptography.X509Certificates; \$store = [X509Store]::new('My', 'CurrentUser', 'ReadWrite'); \$store.Add([X509Certificate2]::new('/home/me/environment-setup/dev.pfx', '$LICENSEPW', [X509KeyStorageFlags]::PersistKeySet)); \$store.Dispose()"

  h3 "Configuring project sectets"
  IDENTITYFINGERPRINT=$(awk '/Identity Server Dev/ { print $4}' fingerprints.txt)
  DATAPROTECTIONFINGERPRINT=$(awk '/Data Protection Dev/ { print $4}' fingerprints.txt)
  sudo rm fingerprints.txt
  sudo mv /home/$OSUSERNAME/environment-setup/secrets.json .
  sudo mv /home/$OSUSERNAME/environment-setup/additional-keys-for-cloud-services.json .

  sudo sed -i "s/DB_PASSWORD/$DBPASSWORD/g" secrets.json
  sudo sed -i "s/DATAPROTECTION_THUMBPRINT/$DATAPROTECTIONFINGERPRINT/g" secrets.json
  sudo sed -i "s/IDENTITY_THUMBPRINT/$IDENTITYFINGERPRINT/g" secrets.json
  sudo sed -i "s/INSTALLATION_ID/$INSTALLATIONID/g" secrets.json
  sudo sed -i "s/INSTALLATION_KEY/$INSTALLATIONKEY/g" secrets.json

  pwsh setup_secrets.ps1
}

setup_bitwarden_clients () {
  h3 "Cloning the client repo"
  cd /home/$OSUSERNAME/$PROJECTSFOLDERNAME
  gh repo clone bitwarden/clients
  cd clients

  h3 "Installing node dependencies for the client repo"
  npm ci

  h3 "Configuring the git blame for the client repo"
  git config blame.ignoreRevsFile .git-blame-ignore-revs
}

install_node () {
  h3 "Installing nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
  export NVM_DIR="$HOME/.nvm" 
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  h3 "Installing node"
  nvm install 'lts/*'
}

setup_web () {
  h3 "Setting up the web vault"
  h3 "Generating a cert"
  install_package "libnss3-tools"
  curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
  chmod +x mkcert-v*-linux-amd64
  sudo cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert
  mkcert --install
  mkcert -cert-file dev-server.local.pem -key-file dev-server.local.pem localhost 127.0.0.1 bitwarden.test
}

setup_desktop () {
  h3 "Installing xfce and vnc"
  install_package "xfce4 xfce4-goodies"
  install_package "tightvncserver"
  mkdir -p /home/$OSUSERNAME/.vnc
  touch /home/$OSUSERNAME/.vnc/xstartup
  cat <<EOT >> /home/$OSUSERNAME/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
startxfce4 &
EOT
  chmod +x /home/$OSUSERNAME/.vnc/xstartup
  sudo touch /etc/systemd/system/vncserver@.service
  sudo cat <<EOT >> /etc/systemd/system/vncserver@.service
[Unit]
Description=Start TightVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=$OSUSERNAME
Group=$OSUSERNAME
WorkingDirectory=/home/$OSUSERNAME

PIDFile=/home/$OSUSERNAME/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1280x800 -localhost :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOT
sudo systemctl daemon-reload
sudo systemctl enable vncserver@1.service
echo "export DISPLAY=:1" >> /home/$OSUSERNAME/.bash_profile
}

setup_directory_connector () {
  cd /home/$OSUSERNAME/$PROJECTSFOLDERNAME
  gh repo clone bitwarden/directory-connector
  cd directory-connector
  npm ci
}

install_git
install_gh
install_docker
setup_commit_signing
update_all_packages
register_microsoft_repo
install_powershell
install_dotnet_sdk
prepare_apps_folder
setup_bitwarden_server
install_node
setup_bitwarden_clients
setup_web
setup_desktop
setup_directory_connector

#!/bin/bash

source /root/environment-setup/formatters.sh

h2 "Configuring an ubuntu user account"

build_user_directory () {
  h3 "Scaffolding user folder and files"
  mkdir -p /home/$OSUSERNAME/.ssh
  mkdir -p /home/$OSUSERNAME/.cache
  touch /home/$OSUSERNAME/.bash_profile
  mkdir /home/$OSUSERNAME/$PROJECTSFOLDERNAME
  echo "export PROJECTS_FOLDER=/home/$OSUSERNAME/$PROJECTSFOLDERNAME" >> /home/$OSUSERNAME/.bash_profile
}

copy_user_ssh_keys () {
  h3 "Copying SSH keys from root"
  cp /root/.ssh/authorized_keys /home/$OSUSERNAME/.ssh/
}

create_user () {
  h3 "Creating a user"
  useradd -G sudo --shell /bin/bash $OSUSERNAME
}

remove_sudo_password_requirement () {
  h3 "Removing the sudo password requirment"
  echo "%sudo ALL=(ALL:ALL) ALL"
  echo "$OSUSERNAME ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$OSUSERNAME
}

set_user_permissions () {
  h3 "Setting permissions for user folders and files"
  chown -R $OSUSERNAME:$OSUSERNAME /home/$OSUSERNAME/
  chown -R $OSUSERNAME:$OSUSERNAME /home/$OSUSERNAME
  chmod 700 /home/$OSUSERNAME/.ssh
  chmod 644 /home/$OSUSERNAME/.ssh/authorized_keys
  chmod 644 /home/$OSUSERNAME/.bash_profile
  chmod 700 /home/$OSUSERNAME/.cache
}

move_self () {
  h3 "Relocating build tools to the user folder"
  sudo mv /root/environment-setup/ /home/$OSUSERNAME/
  chown -R $OSUSERNAME:$OSUSERNAME /home/$OSUSERNAME/environment-setup
}

build_user_directory
copy_user_ssh_keys
create_user
remove_sudo_password_requirement
set_user_permissions
move_self




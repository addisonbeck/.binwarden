#!/bin/bash

# Wrappers 

P="\e["
S="m"
END="${P}0${S}"

# Cyan

C="34"
CYAN="${P}${C}${S}"
BOLDCYAN="${P}1;${C}${S}"
ITALICYELLOW="${P}3;${C}${S}"

# Blue

B="36"
BLUE="${P}${B}${S}"
BOLDBLUE="${P}1;${B}${S}"
ITALICYELLOW="${P}3;${B}${S}"

# Light Cyan

LC="94"
LIGHTCYAN="${P}${LC}${S}"
BOLDLIGHTCYAN="${P}1;${LC}${S}"
ITALICLIGHTCYAN="${P}3;${LC}${S}"

# Light Blue

LB="94"
LIGHTBLUE="${P}${LB}${S}"
BOLDLIGHTBLUE="${P}1;${LB}${S}"
ITALICLIGHTBLUE="${P}3;${LB}${S}"

# Green

G="32"
LIGHTBLUE="${P}${G}${S}"
BOLDLIGHTBLUE="${P}1;${G}${S}"
ITALICLIGHTBLUE="${P}3;${G}${S}"

h1 () {
  echo -e "${BOLDBLUE}${1}${END}"
}

h2 () {
  echo -e "${BLUE}${1}${END}"
}

h3 () {
  echo -e "${CYAN}${1}${END}"
}

success () {
  echo -e "✅ ${GREEN}${1}${END}"
}

install_package () {
  sudo apt-get -qq -o "DPkg::Lock::Timeout=180" install $1 > /dev/null
}

remove_package () {
  sudo apt-get -qq -o "DPkg::Lock::Timeout=180" remove $1 > /dev/null
}

update_packages () {
  sudo apt-get -qq -o "DPkg::Lock::Timeout=180" update > /dev/null
}

upgrade_packages () {
  sudo -E apt-get -qq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" -o "DPkg::Lock::Timeout=180" upgrade > /dev/null
}


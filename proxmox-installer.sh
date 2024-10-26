#!/bin/bash

# This script is based on official Proxmox documentation of how to
# install Proxmox on top of Debian 12 Bookworm.
# https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_12_Bookworm

INSTALLER_VERSION="1.0"

# Define ANSI escape codes
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

repeat_chars() {
  local REPEAT=80
  [ ! -z "$2" ] && REPEAT=$2

  for (( i=1; i<=$REPEAT; i++))
  do
    printf "$1"
  done

  printf "\n"
}

printlog() {
  printf "[Installer] "
  printf "$@"
}

dashed_printlog() {
  repeat_chars '-'
  printlog "$@"
  repeat_chars '-'
}

warning_message() {
  dashed_printlog "Proxmox VE installer script\n"
  printf "It is recommended to run the installer on fresh Debian 12 installation.

Press any key to continue or CTRL+C to abort.\n"

  local _ANY_KEY
  read _ANY_KEY
}

print_help() {
  printf "\
Usage: $0 [OPTIONS]

Where OPTIONS:
  --help                      print this help
  --network-sample-default    print sample of default configuration using a
                              Bridge
  --network-sample-masquerade print sample of masquerade configuration using
                              a Bridge
  --network-sample-routed     print sample of routed configuration using a
                              Bridge
  --version                   print software version and exit

-------------------------- proxmox-installer-sh --------------------------

proxmox-installer-sh is a command line interface helper to install Proxmox VE
on fresh Debian 12 (Bookworm) installation.

proxmox-installer-sh is free software licensed under MIT. Visit the project
homepage at http://github.com/rioastamal/proxmox-installer-sh.
"
}

write_installer_step_file() {
  local STEP="$1"
  local STEP_DIR="/opt/proxmox-installer-sh"
  [ ! -d "$STEP_DIR" ] && mkdir -p "$STEP_DIR"

  printlog "Writing step -> ${STEP}\n"

  [ "$STEP" = "one" ] && {
    printlog "Write step file to ${STEP_DIR}/step-one-done\n"
    touch "${STEP_DIR}/step-one-done"
    return 0
  }

  [ "$STEP" = "two" ] && {
    printlog "Write step file to ${STEP_DIR}/step-two-done\n"
    touch "${STEP_DIR}/step-two-done"
    return 0
  }

  return 1
}

detect_current_step() {
  local STEP_DIR="/opt/proxmox-installer-sh"

  [ ! -f "$STEP_DIR/step-one-done" ] && {
    printf "one"
    return 0
  }

  [ ! -f "$STEP_DIR/step-two-done" ] && {
    printf "two"
    return 0
  }

  printf "done"
}

detect_os() {
  [ ! -z "$EMULATE_OS_VERSION" ] && printf "%s" "$EMULATE_OS_VERSION" && return 0
  grep 'VERSION_CODENAME=bookworm' /etc/os-release >/dev/null 2>&1 && printf 'debian_12' && return 0

  printf 'unsupported' && return 1
}

detect_loopback_hostname() {
  local HOSTNAME_IP="$( hostname --ip-address )"
  [ "$HOSTNAME_IP" = "127.0.0.1" ] && return 1

  return 0
}

is_os_supported() {
  detect_os | grep 'debian_12' && return 0

  # unsupported
  return 1
}

add_proxmox_repo() {
  printlog "Adding deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription to /etc/apt/sources.list.d/pve-install-repo.list\n"
  echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
}

check_gpg_key() {
  local GPG_HASH="7da6fe34168adc6e479327ba517796d4702fa2f8b4f0a9833f5ea6e6b48f6507a6da403a274fe201595edc86a84463d50383d07f64bdde2e3658108db7d6dc87"
  wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
  local DOWNLOAD_HASH="$( sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg | cut -d' ' -f1 )"

  printlog "Comparing hash Expected vs Downloaded\n"
  printlog "$GPG_HASH vs $DOWNLOAD_HASH\n"

  [ "$GPG_HASH" = "$DOWNLOAD_HASH" ] && return 0

  return 1
}

update_os() {
  apt update -y && apt full-upgrade -y
}

install_proxmox_kernel() {
  apt install -y proxmox-default-kernel
}

install_proxmox_ve() {
  apt install -y proxmox-ve postfix open-iscsi chrony
}

remove_debian_kernel() {
  apt remove -y linux-image-amd64 'linux-image-6.1*'
  update_grub
  apt -y remove os-prober
}

install_step1() {
  detect_loopback_hostname || {
    dashed_printlog "Error: Hostname must not resolve to loopback address 127.0.0.1.\n"
    exit 1
  }

  dashed_printlog "Add Proxmox VE repository.\n"
  add_proxmox_repo

  dashed_printlog "Check GPG key.\n"
  check_gpg_key || {
    printlog "Error: GPG key not matched.\n"
    return 1
  }

  printlog "GPG is matched. OK.\n"

  dashed_printlog "Updating OS.\n"
  update_os

  dashed_printlog "Install Proxmox kernel.\n"
  install_proxmox_kernel

  dashed_printlog "Write installer flag for step one.\n"
  write_installer_step_file "one"

  printlog "${BOLD}${RED}After rebooting, run the installer for the second time to complete
the installation process.${RESET}\n"

  local _ANY_KEY
  printf "Press any key to reboot: "
  read _ANY_KEY
  systemctl reboot

  exit 0
}

install_step2() {
  dashed_printlog "Install Proxmox VE.\n"
  install_proxmox_ve

  dashed_printlog "Remove Debian kernel.\n"
  remove_debian_kernel

  dashed_printlog "Write installer flag for step two.\n"
  write_installer_step_file "two"

  local CURRENT_IP="$( hostname -I | cut -d' ' -f1 )"
  printlog "${BOLD}${GREEN}Proxmox VE has been successfully installed (o_o)9${RESET}

You can access Proxmox via following URL:
${BOLD}${GREEN}https://${CURRENT_IP}:8006/${RESET}

You may want setup password for user root by running ${BOLD}passwd${RESET} command.\n\n"
}

network_sample_default() {
  dashed_printlog "Network configuration sample for default bridge.\n"
  printf -- "\
--BEGIN SAMPLE of /etc/network/interfaces--
auto lo
iface lo inet loopback

iface eno1 inet manual

# Change 192.168.10.2/24 to your own IP
auto vmbr0
iface vmbr0 inet static
        address 192.168.10.2/24
        gateway 192.168.10.1
        bridge-ports eno1
        bridge-stp off
        bridge-fd 0
--END SAMPLE--\n"
}

network_sample_routed() {
  dashed_printlog "Network configuration sample for routed.\n"
  printf -- "\
--BEGIN SAMPLE of /etc/network/interfaces--
auto lo
iface lo inet loopback

# Change 198.51.100.5/29 to your own IP
auto eno0
iface eno0 inet static
        address  198.51.100.5/29
        gateway  198.51.100.1
        post-up echo 1 > /proc/sys/net/ipv4/ip_forward
        post-up echo 1 > /proc/sys/net/ipv4/conf/eno0/proxy_arp

# Change 203.0.113.17/28 to your own IP
auto vmbr0
iface vmbr0 inet static
        address 203.0.113.17/28
        bridge-ports none
        bridge-stp off
        bridge-fd 0
--END SAMPLE--
"
}

network_sample_masquerade() {
  dashed_printlog "Network configuration sample for Masquerading (NAT).\n"
  printf -- "\
--BEGIN SAMPLE of /etc/network/interfaces--
auto lo
iface lo inet loopback

# Change 198.51.100.5/24 to your own IP
auto eno1
#real IP address
iface eno1 inet static
        address 198.51.100.5/24
        gateway 198.51.100.1

# Change 10.10.10.1/24 to your own IP
auto vmbr0
#private sub network
iface vmbr0 inet static
        address 10.10.10.1/24
        bridge-ports none
        bridge-stp off
        bridge-fd 0

        post-up   echo 1 > /proc/sys/net/ipv4/ip_forward
        post-up   iptables -t nat -A POSTROUTING -s '10.10.10.0/24' -o eno1 -j MASQUERADE
        post-up   iptables -t raw -I PREROUTING -i fwbr+ -j CT --zone 1
        post-down iptables -t nat -D POSTROUTING -s '10.10.10.0/24' -o eno1 -j MASQUERADE
        post-down iptables -t raw -D PREROUTING -i fwbr+ -j CT --zone 1
--END SAMPLE--
"
}

run_installer() {
  [ "$( detect_current_step )" = "one" ] && {
    warning_message
    install_step1
    return 0
  }

  [ "$( detect_current_step )" = "two" ] && {
    install_step2
    return 0
  }

  dashed_printlog "\
Nothing to do, it seems Proxmox has been successfully installed.

Delete /opt/proxmox-installer-sh directory if you want force the installer to
run.\n"
  return 0
}

SCRIPT_ACTION="run_installer"

# Parse the arguments
while [ $# -gt 0 ]; do
  case $1 in
    --help)
      SCRIPT_ACTION="print_help"
    ;;

    --version)
      printf "version %s\n" $INSTALLER_VERSION
      exit 0
    ;;

    --network-sample-default)
      SCRIPT_ACTION="network_sample_default"
    ;;

    --network-sample-routed)
      SCRIPT_ACTION="network_sample_routed"
    ;;

    --network-sample-masquerade)
      SCRIPT_ACTION="network_sample_masquerade"
    ;;

    *)
      printf "Unrecognised option passed: %s\n\n" "$1" >&2;
      printf "See --help for list of options.\n"
      exit 1
    ;;
  esac
  shift
done

"$SCRIPT_ACTION"
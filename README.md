## Proxmox VE Installer Script on Debian 12 (Bookworm)

This script simplifies the process of installing Proxmox VE on a fresh Debian 12 (Bookworm) installation. It follows the official Proxmox installation guide, adding functions for pre-install checks, Proxmox repository setup, GPG verification, OS update, and kernel installations.

To begin the installation run following command.

```sh
bash ./proxmox-installer.sh
```


### Table of Contents

- [Installation Prerequisites](#installation-prerequisites)
- [Quick Start](#quick-start)
- [Script Options](#script-options)
- [What does the installer do?](#what-does-the-installer-do)
- [Network Configuration Samples](#network-configuration-samples)
- [Troubleshooting](#troubleshooting)
- [License](#license)


### Installation Prerequisites

Ensure the system meets the following:

- A **fresh Debian 12 (Bookworm)** installation.
- Network connectivity to download Proxmox repositories and updates.

**Note**: This script will modify kernel packages, remove the Debian default kernel, and perform a full system upgrade.


### Quick Start

1. Clone the repository:

    ```sh
    git clone https://github.com/rioastamal/proxmox-installer-sh.git
    cd proxmox-installer-sh
    ```

2. Run the installer script:

    ```sh
    bash proxmox-installer.sh
    ```

3. Reboot the system when prompted and re-run the script to complete the installation.


   ```sh
   bash proxmox-installer.sh
   ```


### Script Options

To see more options run with `--help` flag.


```sh
Usage: ./proxmox-installer.sh [OPTIONS]

Where OPTIONS:
  --help                      Display help information
  --network-sample-default    Display default bridge network configuration
  --network-sample-masquerade Display masquerade (NAT) network configuration
  --network-sample-routed     Display routed network configuration
  --version                   Print installer version
```

### What does the installer do?

#### Step 1

The script performs the following actions:

1. Hostname Check: Confirms the hostname does not resolve to the loopback IP (127.0.0.1).
1. Repository Setup: Adds the Proxmox VE repository to sources.list.d.
1. GPG Key Verification: Downloads and verifies the Proxmox GPG key.
1. OS Update and Kernel Installation: Installs Proxmox VE kernel packages.


#### Step 2

Upon reboot, re-run the installer to complete the following:

1. Install Proxmox Packages: Installs the Proxmox VE, postfix, open-iscsi, and chrony packages.
1. Remove Debian Kernel: Uninstalls the Debian default kernel and updates the boot loader.

Upon completion, access Proxmox VE via `https://<YOUR_SERVER_IP>:8006/`.

### Network Configuration Samples

The script includes samples for network configurations typically used in Proxmox environments. To view a sample, pass the relevant option:

#### Default Bridge

```sh
bash ./proxmox-installer.sh --network-sample-default
```

#### Routed Network

```sh
bash ./proxmox-installer.sh --network-sample-routed
```

#### Masquerade (NAT)

```sh
bash ./proxmox-installer.sh --network-sample-masquerade
```

### Troubleshooting

If the installation fails, verify the following:

- You’re using Debian 12 (Bookworm) without prior modifications.
- Network connectivity to the Proxmox repository and GPG server.
- Check the Proxmox installation log output for errors.

To re-run the installer from scratch, delete the `/opt/proxmox-installer-sh` directory to reset the installation flags.

### License

This project is licensed under the MIT License. See the LICENSE file for more information.

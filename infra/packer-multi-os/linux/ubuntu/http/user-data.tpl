#cloud-config
# Ubuntu 22.04 LTS Autoinstall Configuration
#
# Generic Packer template with dynamic SSH key injection.
#
# Template variables (replaced during rendering):
#   __VAR_SSH_PUBLIC_KEY__  - Authorized SSH public key
#
# Author: Jeleel Muibi | HybridOps.Studio
# Date: 2025-11-13

autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us

  identity:
    hostname: ubuntu-template
    username: hybridops
    # Password: 'Temporary!' (must match ssh_password variable in Packer)
    password: "Temporary!"

  ssh:
    install-server: true
    allow-pw: true
    authorized-keys:
    - __VAR_SSH_PUBLIC_KEY__

  network:
    version: 2
    ethernets:
      id0:
        match:
          name: "e*"
        dhcp4: true

  storage:
    layout:
      name: direct

  packages:
  - qemu-guest-agent
  - cloud-init
  - openssh-server

  late-commands:
  - curtin in-target --target=/target -- systemctl enable qemu-guest-agent
  - echo "hybridops ALL=(ALL) NOPASSWD:ALL" > /target/etc/sudoers.d/hybridops
  - chmod 0440 /target/etc/sudoers.d/hybridops
  - curtin in-target --target=/target -- systemctl enable ssh

# ks-rocky.cfg.tpl
# Purpose: Shared Kickstart template for Rocky Linux 9/10 Packer builds
# Maintainer: HybridOps.Studio
# Date: 2025-11-15
# Compatible: Rocky Linux 9.x, 10.x

cdrom
text

lang en_US.UTF-8
keyboard us
timezone UTC --utc

network --bootproto=dhcp --device=link --activate --onboot=yes
network --hostname=rocky-template

# Root password (locked)
rootpw --lock

# Create user with temporary password
# Password: 'Temporary!' (must match ssh_password variable in Packer)
user --name=hybridops --groups=wheel --plaintext --password=Temporary!

firewall --disabled
selinux --permissive

zerombr
clearpart --all --initlabel
autopart --type=lvm
bootloader --location=mbr --boot-drive=sda

services --enabled=sshd,chronyd
skipx
reboot

%packages --ignoremissing
@core
@standard
qemu-guest-agent
cloud-init
cloud-utils-growpart
sudo
curl
wget
python3
openssh-server
openssh-clients
-plymouth
%end

%post --log=/root/ks-post.log

# Configure authentication in post
authselect select sssd --force || true

# Configure passwordless sudo for wheel group
echo '%wheel ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel

# Configure SSH for hybridops user
mkdir -p /home/hybridops/.ssh
chmod 0700 /home/hybridops/.ssh

# Inject SSH public key
cat > /home/hybridops/.ssh/authorized_keys <<'SSHEOF'
__VAR_SSH_PUBLIC_KEY__
SSHEOF

chmod 0600 /home/hybridops/.ssh/authorized_keys
chown -R hybridops:hybridops /home/hybridops/.ssh

# Configure SSHD
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/50-packer.conf <<'SSHDEOF'
PubkeyAuthentication yes
PasswordAuthentication yes
PermitRootLogin no
SSHDEOF

# Enable services
systemctl enable sshd.service
# Enable cloud-init services (ensures they start on boot)
systemctl enable cloud-init-local.service || true
systemctl enable cloud-init.service || true
systemctl enable cloud-config.service || true
systemctl enable cloud-final.service || true
echo "cloud-init services enabled" >> /root/ks-post. log

# Verify cloud-init installation
if rpm -q cloud-init >/dev/null 2>&1; then
  echo "cloud-init installed successfully" >> /root/ks-post.log
  rpm -qa | grep cloud >> /root/ks-post. log
else
  echo "ERROR: cloud-init NOT installed!" >> /root/ks-post. log
fi

# Configure NetworkManager fallback for eth0 (resilient to cloud-init failures)
echo "Configuring NetworkManager fallback for eth0..." >> /root/ks-post.log
mkdir -p /etc/NetworkManager/system-connections
cat > /etc/NetworkManager/system-connections/eth0.nmconnection <<'NMEOF'
[connection]
id=eth0
uuid=00000000-0000-0000-0000-000000000000
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=999

[ethernet]

[ipv4]
method=auto
dns-search=

[ipv6]
addr-gen-mode=stable-privacy
method=auto

[proxy]
NMEOF

chmod 600 /etc/NetworkManager/system-connections/eth0.nmconnection
chown root:root /etc/NetworkManager/system-connections/eth0.nmconnection

# Ensure NetworkManager will manage eth0
mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/99-manage-eth0.conf <<'NMCONFEOF'
[main]
no-auto-default=

[keyfile]
unmanaged-devices=
NMCONFEOF

echo "NetworkManager fallback configured" >> /root/ks-post.log

# Ensure qemu-guest-agent is installed and enabled
if rpm -q qemu-guest-agent >/dev/null 2>&1; then
  systemctl unmask qemu-guest-agent.service || true
  systemctl enable qemu-guest-agent.service || true
  echo "qemu-guest-agent enabled" >> /root/ks-post.log
else
  echo "WARNING: qemu-guest-agent package not installed" >> /root/ks-post.log
  dnf install -y qemu-guest-agent || echo "Failed to install qemu-guest-agent" >> /root/ks-post.log
  systemctl enable qemu-guest-agent.service || true
fi

# Configure cloud-init for Proxmox
mkdir -p /etc/cloud/cloud.cfg.d
cat > /etc/cloud/cloud.cfg.d/99_pve.cfg <<'CLOUDEOF'
datasource_list: [ NoCloud, ConfigDrive ]
disable_root: true
ssh_pwauth: false
manage_etc_hosts: true
preserve_hostname: false
CLOUDEOF

# Lock root account
passwd -l root

# Cleanup
dnf clean all
rm -rf /var/cache/dnf /tmp/* /var/tmp/*
rm -f /etc/ssh/ssh_host_*
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id
find /var/log -type f -exec truncate -s 0 {} \;

echo "Rocky Linux Kickstart completed at $(date)" >> /root/ks-post.log
echo "User: hybridops" >> /root/ks-post.log
echo "NetworkManager fallback: eth0 will auto-connect with DHCP" >> /root/ks-post.log
echo "Template ready for cloud-init configuration" >> /root/ks-post.log

%end

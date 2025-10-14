#!/usr/bin/env bash
set -euo pipefail

# ---- settings (edit if needed) ----
VMID=${VMID:-101}
VMNAME=${VMNAME:-ctrl-01}
BRIDGE=${BRIDGE:-vmbr1}
IPCIDR=${IPCIDR:-172.16.10.5/28}
GATEWAY=${GATEWAY:-172.16.10.1}
DNS1=${DNS1:-8.8.8.8}
DNS2=${DNS2:-192.168.0.1}
DISKSTORE=${DISKSTORE:-local-lvm}
SNIPSTORE=${SNIPSTORE:-local}
SNIPFILE=${SNIPFILE:-ctrl01-minimal-cloudinit.yaml}
SSH_PUBKEY=${SSH_PUBKEY:-/root/.ssh/id_rsa.pub}
CIUSER=${CIUSER:-rocky}
ROCKY_IMG_URL=${ROCKY_IMG_URL:-https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2}
ROCKY_IMG_PATH="/var/lib/vz/template/iso/$(basename "$ROCKY_IMG_URL")"
# -----------------------------------

echo "==> enable 'snippets' on ${SNIPSTORE}"
pvesm set "${SNIPSTORE}" --content vztmpl,iso,backup,snippets >/dev/null 2>&1 || true
install -d -m 0755 /var/lib/vz/snippets

echo "==> write minimal cloud-init to /var/lib/vz/snippets/${SNIPFILE}"
cat >"/var/lib/vz/snippets/${SNIPFILE}" <<'YAML'
#cloud-config
preserve_hostname: false
hostname: ctrl-01
fqdn: ctrl-01
manage_etc_hosts: true
package_update: true
ssh_pwauth: true

# user 'rocky' with sudo and a temporary password 'TempPass123!' (rotate after first login)
users:
  - name: rocky
    gecos: Rocky User
    groups: wheel
    shell: /bin/bash
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
    # openssl passwd -6 'TempPass123!'
    passwd: $6$uH8J8C1g$8g1s7l7tP3V7m3m3w2v4rQW0Kk8V5Wk3qv7b7r0ZKf0y3FZQ3QmJvZCw9gq8L/2u9S8XW4wJt5wT4eQvFQq.

write_files:
  - path: /usr/local/bin/ctrl01-minimal.sh
    permissions: '0755'
    content: |
      #!/usr/bin/env bash
      set -Eeuo pipefail
      LOG=/var/log/ctrl01_minimal.log
      exec > >(tee -a "$LOG") 2>&1
      echo "[minimal] start $(date -Is)"

      # Prefer IPv4 & stable DNS
      grep -q '::ffff:0:0/96' /etc/gai.conf 2>/dev/null || echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
      if command -v nmcli >/dev/null 2>&1; then
        CONN="$(nmcli -t -f NAME c show --active | head -n1 || true)"
        if [ -n "$CONN" ]; then
          nmcli con mod "$CONN" ipv4.dns "8.8.8.8 192.168.0.1" || true
          nmcli con mod "$CONN" ipv4.ignore-auto-dns yes || true
          nmcli con up "$CONN" || true
        fi
      fi
      printf 'options timeout:2 attempts:2\nnameserver 8.8.8.8\nnameserver 192.168.0.1\n' >/etc/resolv.conf || true

      dnf -y install curl git || true

      echo "[minimal] done $(date -Is)"

runcmd:
  - [ bash, -lc, "sysctl -w net.ipv6.conf.all.disable_ipv6=1" ]
  - [ bash, -lc, "sysctl -w net.ipv6.conf.default.disable_ipv6=1" ]
  - [ bash, -lc, "/usr/local/bin/ctrl01-minimal.sh || true" ]
YAML

echo "==> fetch Rocky image (if missing)"
install -d -m 0755 /var/lib/vz/template/iso
[ -s "$ROCKY_IMG_PATH" ] || wget -O "$ROCKY_IMG_PATH" "$ROCKY_IMG_URL"

echo "==> destroy existing VM $VMID (ignore errors)"
qm stop "$VMID" >/dev/null 2>&1 || true
qm destroy "$VMID" --purge >/dev/null 2>&1 || true

echo "==> create VM shell"
qm create "$VMID" --name "$VMNAME" --memory 4096 --cores 2 --cpu host \
  --net0 virtio,bridge="$BRIDGE" --agent 1 --scsihw virtio-scsi-pci --ostype l26

echo "==> import disk"
qm importdisk "$VMID" "$ROCKY_IMG_PATH" "$DISKSTORE"
qm set "$VMID" --scsi0 "$DISKSTORE:vm-$VMID-disk-0" --boot c --bootdisk scsi0

echo "==> add cloud-init + console"
qm set "$VMID" --ide2 "$DISKSTORE:cloudinit"
qm set "$VMID" --serial0 socket --vga serial0

echo "==> configure cloud-init + network"
[ -f "$SSH_PUBKEY" ] && qm set "$VMID" --sshkey "$SSH_PUBKEY" || true
qm set "$VMID" --ciuser "$CIUSER"
qm set "$VMID" --ipconfig0 "ip=$IPCIDR,gw=$GATEWAY"
qm set "$VMID" --nameserver "$DNS1"
qm set "$VMID" --cicustom "user=$SNIPSTORE:snippets/$SNIPFILE"

echo "==> update seed & show first lines"
qm cloudinit update "$VMID"
qm cloudinit dump "$VMID" user | sed -n '1,120p'

echo "==> start VM"
qm start "$VMID"
echo "Connect: ssh rocky@${IPCIDR%%/*}   (temp password: TempPass123! or your SSH key if injected)"
qm terminal "$VMID"

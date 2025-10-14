#!/usr/bin/env bash
set -euo pipefail

# Recreate ctrl-01 on vmbr1 with 172.168.10.5/28, GW 172.168.10.1, DNS 8.8.8.8 & 192.168.0.1
VMID=${VMID:-101}
VMNAME=${VMNAME:-ctrl-01}
BRIDGE=${BRIDGE:-vmbr1}
IPCIDR=${IPCIDR:-172.16.10.5/28}
GATEWAY=${GATEWAY:-172.16.10.1}
DNS1=${DNS1:-8.8.8.8}
DNS2=${DNS2:-192.168.0.1}
DISKSTORE=${DISKSTORE:-local-lvm}
SNIPSTORE=${SNIPSTORE:-local}
SNIPFILE=${SNIPFILE:-ctrl01-rocky-single-cloudinit.yaml}
SSH_PUBKEY=${SSH_PUBKEY:-/root/.ssh/id_rsa.pub}
CIUSER=${CIUSER:-rocky}
ROCKY_IMG_URL=${ROCKY_IMG_URL:-https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2}
ROCKY_IMG_PATH="/var/lib/vz/template/iso/$(basename "$ROCKY_IMG_URL")"

echo "==> Enable 'snippets' content on ${SNIPSTORE} if needed"
pvesm set "${SNIPSTORE}" --content vztmpl,iso,backup,snippets >/dev/null 2>&1 || true
install -d -m 0755 /var/lib/vz/snippets

echo "==> Write hardened cloud-init to /var/lib/vz/snippets/${SNIPFILE}"
cat >"/var/lib/vz/snippets/${SNIPFILE}" <<'YAML'
#cloud-config
hostname: ctrl-01
manage_etc_hosts: true
package_update: true

write_files:
  - path: /usr/local/bin/ctrl01-unified.sh
    permissions: '0755'
    content: |
      #!/usr/bin/env bash
      set -Eeuo pipefail
      LOG=/var/log/ctrl01_bootstrap.log
      exec > >(tee -a "$LOG") 2>&1
      echo "[bootstrap] start $(date -Is)"
      export LC_ALL=C LANG=C

      retry() { local n=1; local tries="$1"; local sleep_s="$2"; shift 2;
        until "$@"; do
          if [ $n -ge "$tries" ]; then echo "RETRY: giving up after $n: $*"; return 1; fi
          echo "RETRY: $n/$tries failed: $* ; sleeping ${sleep_s}s"; sleep "$sleep_s"; n=$((n+1))
        done
      }

      # IPv4 pref
      grep -q '::ffff:0:0/96' /etc/gai.conf 2>/dev/null || echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf

      # Pin DNS via NetworkManager
      if command -v nmcli >/dev/null 2>&1; then
        CONN="$(nmcli -t -f NAME c show --active | head -n1 || true)"
        if [ -n "$CONN" ]; then
          nmcli con mod "$CONN" ipv4.dns "8.8.8.8 192.168.0.1" || true
          nmcli con mod "$CONN" ipv4.ignore-auto-dns yes || true
          nmcli con up "$CONN" || true
        fi
      fi
      printf 'options timeout:2 attempts:2\nnameserver 8.8.8.8\nnameserver 192.168.0.1\n' >/etc/resolv.conf || true

      # Wait for network + DNS
      retry 10 3 bash -lc 'ping -c1 -W1 8.8.8.8 >/dev/null 2>&1'
      retry 10 3 bash -lc 'getent hosts pkg.jenkins.io >/dev/null 2>&1'

      # Base packages + EPEL
      retry 5 5 dnf -y install dnf-plugins-core curl gnupg2 ca-certificates git make jq unzip wget tar python3-pip firewalld chrony
      retry 5 5 dnf -y install epel-release
      retry 5 5 dnf -y update --refresh
      dnf -y install yq || true

      # HashiCorp tools
      retry 5 5 dnf -y config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
      retry 5 5 dnf -y install packer terraform

      # kubectl repo + install
      cat >/etc/yum.repos.d/kubernetes.repo <<'EOF'
      [kubernetes]
      name=Kubernetes
      baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
      enabled=1
      gpgcheck=1
      gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
      EOF
      retry 5 5 dnf -y install kubectl

      # Helm (dnf or upstream installer)
      if ! dnf -y install helm; then
        retry 5 5 bash -lc 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
      fi

      # Jenkins repo + Java
      retry 10 3 bash -lc 'curl -fsSL https://pkg.jenkins.io/redhat/jenkins.io-2023.key -o /etc/pki/rpm-gpg/RPM-GPG-KEY-jenkins'
      rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-jenkins || true
      cat >/etc/yum.repos.d/jenkins.repo <<'EOF'
      [jenkins]
      name=Jenkins-stable
      baseurl=https://pkg.jenkins.io/redhat-stable
      gpgcheck=1
      gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-jenkins
      enabled=1
      EOF
      retry 5 5 dnf -y install fontconfig java-21-openjdk jenkins
      systemctl enable --now jenkins || true

      # Ansible (user scope)
      pip3 install --user ansible || true
      echo 'export PATH=$HOME/.local/bin:$PATH' >/etc/profile.d/99-localbin.sh

      # Repo checkout
      mkdir -p /srv
      if [ ! -d /srv/hybridops/.git ]; then
        retry 5 5 git clone https://github.com/jeleel-muibi/hybridops.studio /srv/hybridops || true
      fi
      (cd /srv/hybridops && git fetch --all && git switch main && git pull) || true

      # Optional make targets
      if grep -qE '^\s*env\.setup:' /srv/hybridops/Makefile 2>/dev/null; then
        (cd /srv/hybridops && make env.setup sanity || true)
      else
        (cd /srv/hybridops && ( make init || true ) && ( make doctor || true ))
      fi

      # Firewall & time sync
      systemctl enable --now firewalld || true
      firewall-cmd --permanent --add-service=ssh || true
      firewall-cmd --permanent --add-port=8080/tcp || true
      firewall-cmd --reload || true
      systemctl enable --now chronyd || true

      echo "[bootstrap] done $(date -Is)"

runcmd:
  - [ bash, -lc, "sysctl -w net.ipv6.conf.all.disable_ipv6=1" ]
  - [ bash, -lc, "sysctl -w net.ipv6.conf.default.disable_ipv6=1" ]
  - [ bash, -lc, "/usr/local/bin/ctrl01-unified.sh || (echo BOOTSTRAP_RC=$? | tee /var/log/ctrl01_bootstrap.rc; exit 0)" ]
YAML

echo "==> Download Rocky 9 GenericCloud image if missing"
install -d -m 0755 /var/lib/vz/template/iso
[ -s "$ROCKY_IMG_PATH" ] || wget -O "$ROCKY_IMG_PATH" "$ROCKY_IMG_URL"

echo "==> Destroy any existing VMID ${VMID} (ignore errors)"
qm stop "${VMID}" >/dev/null 2>&1 || true
qm destroy "${VMID}" --purge >/dev/null 2>&1 || true

echo "==> Create VM shell"
qm create "${VMID}" --name "${VMNAME}" --memory 4096 --cores 2 --cpu host \
  --net0 virtio,bridge="${BRIDGE}" --agent 1 --scsihw virtio-scsi-pci --ostype l26

echo "==> Import disk"
qm importdisk "${VMID}" "${ROCKY_IMG_PATH}" "${DISKSTORE}"
qm set "${VMID}" --scsi0 "${DISKSTORE}:vm-${VMID}-disk-0" --boot c --bootdisk scsi0

echo "==> Add cloud-init drive and console"
qm set "${VMID}" --ide2 "${DISKSTORE}:cloudinit"
qm set "${VMID}" --serial0 socket --vga serial0

echo "==> Configure networking & cloud-init parameters"
if [ -f "${SSH_PUBKEY}" ]; then
  qm set "${VMID}" --sshkey "${SSH_PUBKEY}"
else
  echo "WARNING: SSH public key ${SSH_PUBKEY} not found; continuing without key injection" >&2
fi
qm set "${VMID}" --ciuser "${CIUSER}"
qm set "${VMID}" --ipconfig0 "ip=${IPCIDR},gw=${GATEWAY}"
qm set "${VMID}" --nameserver "${DNS1}"
qm set "${VMID}" --cicustom "user=${SNIPSTORE}:snippets/${SNIPFILE}"

echo "==> Update cloud-init seed and verify user-data snippet"
qm cloudinit update "${VMID}"
qm cloudinit dump "${VMID}" user | sed -n '1,160p'

echo "==> Start VM and open terminal"
qm start "${VMID}"
echo "Tip: after SSH is up -> ssh ${CIUSER}@${IPCIDR%%/*}"
echo "     logs: sudo tail -f /var/log/cloud-init-output.log /var/log/ctrl01_bootstrap.log"
qm terminal "${VMID}"

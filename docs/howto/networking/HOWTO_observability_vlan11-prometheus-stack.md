---
title: "HOWTO: Deploy Observability Stack (Prometheus/Grafana/Loki) in VLAN 11"
category: "observability"
summary: "Step-by-step guide to deploy a unified Prometheus + Grafana + Loki stack in the observability VLAN (VLAN 11)."
difficulty: "Intermediate"

topic: "observability-vlan11-stack"

video: "https://www.youtube.com/watch?v=YOUR_OBSERVABILITY_VIDEO_ID"
source: ""

draft: false
tags: ["prometheus", "grafana", "loki", "observability", "vlan11"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Deploy Observability Stack (Prometheus/Grafana/Loki) in VLAN 11

**Purpose:** Deploy a unified Prometheus + Grafana + Loki stack in VLAN 11 so you can observe dev/staging/prod clusters from a single pane of glass.  
**Difficulty:** Intermediate  
**Prerequisites:**
- VLAN 11 (Observability) configured as per ADR‑0101 and reachable from management.
- Proxmox VM templates ready (Linux base with cloud-init).
- Basic familiarity with systemd services and Docker/Podman *or* native binaries.

---

## Demo / Walk-through

??? info "▶ Watch the observability stack walk-through"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_OBSERVABILITY_VIDEO_ID"
      title="Observability Stack in VLAN 11 – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_OBSERVABILITY_VIDEO_ID){ target=_blank rel="noopener" }

---

## 1. Context

This HOWTO complements decisions captured in:

- ADR-0101 – VLAN Allocation Strategy
- ADR-0103 – Inter-VLAN Firewall Policy
- ADR-0401 – Unified Observability with Prometheus
- Network Architecture overview

The observability stack lives in VLAN 11 and:

- Scrapes metrics from workloads in VLANs 20/30/40.  
- Serves dashboards to authorised users in management VLAN 10.  
- Stores logs centrally via Loki to correlate incidents across environments.

This guide uses VM-per-component (Prometheus, Grafana, Loki) but can be adapted to containers or Kubernetes later.

---

## 2. Lab Assumptions

Replace the examples with your real values.

### 2.1 Networks and Hosts

| Item                 | Example value         |
|----------------------|----------------------|
| VLAN ID              | 11                   |
| Subnet               | 10.11.0.0/24         |
| Gateway (Proxmox)    | 10.11.0.1            |
| Prometheus VM        | 10.11.0.10           |
| Grafana VM           | 10.11.0.11           |
| Loki VM              | 10.11.0.12           |
| Management jump host | 10.10.0.10           |

### 2.2 Access and Tools

- SSH access from VLAN 10 to VLAN 11.  
- Terraform + Ansible available on your management host.  
- DNS or `/etc/hosts` entries for `prometheus.lab`, `grafana.lab`, `loki.lab` (optional but recommended).

---

## 3. Provision the VMs in VLAN 11

You can use Terraform modules or Proxmox GUI; the important part is:

- Each VM attaches to the Proxmox bridge for VLAN 11.  
- Static IPs are assigned according to ADR‑0104 (Terraform IPAM is preferred).

### 3.1 Using Terraform IPAM + VM module (recommended)

```hcl
module "ipam_observability" {
  source = "../../modules/proxmox/ipam"

  allocations = {
    prometheus-01 = { vlan = 11, offset = 10 } # 10.11.0.10
    grafana-01    = { vlan = 11, offset = 11 } # 10.11.0.11
    loki-01       = { vlan = 11, offset = 12 } # 10.11.0.12
  }
}

module "vm_observability" {
  source = "../../modules/proxmox/vm"

  vms = {
    prometheus-01 = {
      ipv4_address = module.ipam_observability.ipv4_addresses["prometheus-01"]
      ipv4_gateway = module.ipam_observability.gateways[11]
      # other CPU/RAM/template settings
    }
    # grafana-01, loki-01...
  }
}
```

Apply and verify that all three VMs:

```bash
ping -c3 10.11.0.10
ping -c3 10.11.0.11
ping -c3 10.11.0.12
```

---

## 4. Install and Configure Prometheus

### 4.1 Install Prometheus

On `prometheus-01`:

```bash
sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus || true
sudo mkdir -p /etc/prometheus /var/lib/prometheus

wget https://github.com/prometheus/prometheus/releases/download/v2.55.0/prometheus-2.55.0.linux-amd64.tar.gz
tar -xzf prometheus-2.55.0.linux-amd64.tar.gz
cd prometheus-2.55.0.linux-amd64

sudo cp prometheus promtool /usr/local/bin/
sudo cp -r consoles console_libraries /etc/prometheus/
```

### 4.2 Base configuration

`/etc/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 30s

scrape_configs:
  - job_name: 'node-dev'
    static_configs:
      - targets:
          - '10.20.0.10:9100'
          - '10.20.0.11:9100'
        labels:
          environment: dev

  - job_name: 'node-staging'
    static_configs:
      - targets:
          - '10.30.0.10:9100'
        labels:
          environment: staging

  - job_name: 'node-prod'
    static_configs:
      - targets:
          - '10.40.0.10:9100'
        labels:
          environment: prod
```

### 4.3 Systemd service

`/etc/systemd/system/prometheus.service`:

```ini
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus       --config.file=/etc/prometheus/prometheus.yml       --storage.tsdb.path=/var/lib/prometheus       --web.listen-address=0.0.0.0:9090

[Install]
WantedBy=multi-user.target
```

```bash
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
```

Validate:

```bash
curl -s http://10.11.0.10:9090/metrics | head
```

---

## 5. Install and Configure Grafana

On `grafana-01` (Ubuntu example):

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana
sudo systemctl enable --now grafana-server
```

Add Prometheus data source via UI (or provisioning):

- URL: `http://10.11.0.10:9090`  
- Access: `Server`  

Create an “Environment Overview” dashboard with:

- Variable `environment` (dev|staging|prod).  
- Panels for CPU, memory, node count filtered by label.

---

## 6. Install and Configure Loki (Optional but Recommended)

On `loki-01`:

```bash
wget https://github.com/grafana/loki/releases/download/v3.1.0/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
sudo mv loki-linux-amd64 /usr/local/bin/loki
sudo chmod +x /usr/local/bin/loki
```

Minimal config `/etc/loki/loki.yml` (single-node):

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
  chunk_idle_period: 5m

schema_config:
  configs:
    - from: 2024-01-01
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb:
    directory: /var/lib/loki/index
  filesystem:
    directory: /var/lib/loki/chunks
```

Create systemd unit similar to Prometheus and start Loki on `:3100`.  
Configure Grafana Loki data source pointing at `http://10.11.0.12:3100`.

---

## 7. Firewall and Connectivity Validation

Ensure firewall rules from ADR‑0103 allow:

- From VLAN 11 to dev/staging/prod on exporter ports (e.g. 9100, 10250, etc.).  
- From VLAN 10 (management) to VLAN 11 on 9090 (Prometheus), 3000 (Grafana), 3100 (Loki, if required).

Basic checks:

```bash
# From management jump host
curl -I http://10.11.0.10:9090
curl -I http://10.11.0.11:3000

# From prometheus-01
curl -I http://10.20.0.10:9100
```

In Grafana, confirm:

- Prometheus data source shows as **green**.  
- Environment dashboards show metrics for dev/staging/prod.  

---

## 8. Validation Checklist

- [ ] Prometheus VM up in VLAN 11 and reachable on `:9090`.  
- [ ] Grafana VM up in VLAN 11 and reachable on `:3000`.  
- [ ] (Optional) Loki VM up in VLAN 11 and reachable on `:3100`.  
- [ ] Firewall allows Prometheus to scrape exporters in VLANs 20/30/40.  
- [ ] Grafana dashboards show environment-labelled metrics.  
- [ ] Prometheus rules / alerts fire correctly in test scenarios.

---

## References

- [ADR‑0101 – VLAN Allocation Strategy](../adr/ADR-0101-vlan-allocation-strategy.md)  
- [ADR‑0103 – Inter-VLAN Firewall Policy](../adr/ADR-0103-inter-vlan-firewall-policy.md)  
- [ADR‑0401 – Unified Observability with Prometheus](../adr/ADR-0401-unified-observability-prometheus.md)  
- [Network Architecture](../prerequisites/network-architecture.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

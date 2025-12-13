# Reddit Posting Playbook – Proxmox Packer VM Templates

Internal notes and drafts for promoting the Proxmox Packer VM template tooling alongside the SDN/Terraform work.

This focuses on:

- Golden images for Ubuntu, Rocky, and Windows Server/Client.
- Makefile-driven builds.
- Evidence + HOWTO + runbook story.
- Integration with Terraform/Terragrunt stacks.

---

## 1. Overview

**Goal**

Show how the Packer layer gives you **repeatable, cloud-init-capable Proprox VE templates** in minutes, instead of hand-building VMs in the UI every time.

This should complement (not compete with) the SDN/Terraform posts:

- SDN: “I automated the network.”
- Packer: “I automated the VM base images.”

**Key value props**

- One-command builds for Ubuntu 22.04/24.04, Rocky 9/10, Windows Server 2022/2025, Windows 11.
- Consistent VMIDs and naming conventions (e.g. 9000–9102).
- Cloud-init/autounattend baked in.
- Evidence + ADR-0016 + HOWTO + runbook = “not just scripts, but a small platform.”

**GitHub repo (placeholder)**  
`[your-repo-link-here]`

---

## 2. Post Drafts by Subreddit

### 2.1 r/Proxmox – “stop hand-building templates”

**Title:**  
`Reusable Proxmox VM templates with Packer (Ubuntu, Rocky, Windows Server)`

**Body:**

Hey r/Proxmox,

I got tired of hand-building “golden images” in the Proxmox UI every time I wanted a clean Ubuntu/Rocky/Windows template.

So I built a Packer workspace that spits out **reusable, cloud-init-capable VM templates** for Proxmox in a few minutes, with a simple Makefile interface.

**What it builds**

From one repo / workspace you get templates like:

- `ubuntu-2204` (VMID 9000) – Ubuntu 22.04 LTS  
- `ubuntu-2404` (VMID 9001) – Ubuntu 24.04 LTS  
- `rocky-9` (VMID 9002) – Rocky Linux 9  
- `rocky-10` (VMID 9003) – Rocky Linux 10  
- `windows-server-2022` (VMID 9100)  
- `windows-server-2025` (VMID 9101)  
- `windows-11-enterprise` (VMID 9102)  

All of them are:

- Cloud-init-ready (Linux) or Autounattend-based (Windows)
- Prepped with guest agent / sensible defaults
- Built the same way every time from code

**Repository structure (high level)**

```text
infra/packer-multi-os/
├── Makefile
├── shared/           # .env, generic builder, plugin config
├── linux/
│   ├── ubuntu/       # user-data.tpl + vars for 22.04/24.04
│   └── rocky/        # ks.cfg.tpl + vars for 9/10
└── windows/
    ├── server/       # Autounattend + vars for 2022/2025
    └── client/       # Windows 11 Enterprise
```

**How you use it**

1. Configure Proxmox API + storage in `.env`:

```bash
cd infra/packer-multi-os
cp shared/.env.example shared/.env
# edit URL, token, storage pools, etc.
```

2. Initialise and build:

```bash
make init

make build-ubuntu-22.04
make build-rocky-9
make build-windows-server-2022
```

3. (Optional) Override VMIDs if needed:

```bash
UBUNTU22_VMID=9100 make build-ubuntu-22.04
```

Under the hood there’s a generic builder + per-OS var files, so adding new OS versions is mostly a case of adding a new `*.pkrvars.hcl`.

**Docs & design**

- HOWTO: step-by-step template build  
- Runbook: troubleshooting builds  
- ADR-0016: design decisions (cloud-init, VMID ranges, etc.)

GitHub: `[your-repo-link-here]`

It’s MIT-0 licensed. If you’ve been meaning to standardise your Proxmox templates, happy to share details or get feedback on the structure.

---

### 2.2 r/homelab – “golden images for fast rebuilds”

**Title:**  
`Golden images for a Proxmox homelab: Packer + Makefile`

**Body:**

One thing that always slowed down my homelab was rebuilding base images.

Every time I wanted a clean Ubuntu/Rocky/Windows VM, I’d either clone an old VM (with mystery history) or reinstall from ISO. So I put together a Packer workspace that builds **golden images** for Proxmox in a consistent way.

**What it gives you**

- A set of **standard templates** for:
  - Ubuntu 22.04 / 24.04
  - Rocky Linux 9 / 10
  - Windows Server 2022 / 2025
  - Windows 11 Enterprise
- Consistent VMIDs and names (easy to script against)
- Cloud-init/autounattend baked in
- Build logs + evidence so you know exactly what was installed

**Usage is simple**

From the repo:

```bash
cd infra/packer-multi-os

# One-time init (plugins, .env template, etc.)
make init

# Build whatever you need today
make build-ubuntu-24.04
make build-rocky-10
make build-windows-server-2025
```

Now, when you want to spin up a new VM in your lab, you’re always starting from a known-good template instead of a random snowflake VM from 6 months ago.

**Why it helps in a lab**

- Easy to nuke and rebuild environments (you’re never afraid to destroy VMs).
- Repeatable test setups (same base image every time).
- Good practice for doing image pipelines “the way it’s done” in real environments.

Docs include a HOWTO, an operations runbook for when builds fail, and an ADR explaining why it’s designed this way.

GitHub: `[your-repo-link-here]`

If you’ve built similar Proxmox image pipelines in your homelab, I’d love to compare notes.

---

### 2.3 r/selfhosted – “clean base images for your apps”

**Title:**  
`Automated Proxmox base images for self-hosted apps (Ubuntu, Rocky, Windows)`

**Body:**

For anyone running self-hosted apps on Proxmox: I got tired of guessing what was inside my “base VM” every time I spun up a new service.

So I put together a Packer setup that builds **clean, versioned base images** for Ubuntu, Rocky, and Windows, with a simple Makefile interface.

**Examples**

- Ubuntu 22.04 / 24.04 templates for Docker/Kubernetes nodes  
- Rocky 9 / 10 templates for “RHEL-ish” services  
- Windows Server 2022 / 2025 and Windows 11 Enterprise for anything that needs a Windows base  

All built from code, with cloud-init/autounattend baked in.

**Why this is useful for self-hosting**

- When you create a new VM for “Nextcloud #3” or “new reverse proxy”, you know exactly what base image it’s from.
- Rebuilding is cheap – if you mess something up, destroy and re-deploy from the same template.
- It plays nicely with Terraform/Ansible if you want to go further into IaC later.

**How it runs**

```bash
cd infra/packer-multi-os
make init

make build-ubuntu-24.04
make build-rocky-9
make build-windows-server-2022
```

Everything is version-controlled, and there are docs + an operations runbook for when Packer fails in “interesting” ways.

GitHub: `[your-repo-link-here]`

MIT-0 licensed. Happy to answer questions if you want to wire this into a self-hosted stack.

---

### 2.4 r/devops – “image pipeline for on-prem Proxmox”

**Title:**  
`Image pipeline for Proxmox: Packer + generic builder + evidence`

**Body:**

If you care about image pipelines but are stuck on-prem, here’s one approach I’ve been using for Proxmox.

Instead of hand-maintained “golden VMs”, I use a Packer workspace with:

- A generic Proxmox VM builder (`generic.pkr.hcl`)
- OS-specific var files (Ubuntu, Rocky, Windows)
- A Makefile that wraps the common flows
- ADR + HOWTO + runbook so the whole thing is explainable

**Highlights**

- Ubuntu, Rocky, and Windows Server/Client templates built from the same pattern.
- `.env`-driven configuration for Proxmox URL, token, storage pools, etc.
- Cloud-init/autounattend baked into the templates.
- Evidence stored for each build (logs, metadata) so you can defend what went into the image.

**Structure**

```text
infra/packer-multi-os/
├── Makefile
├── shared/
│   ├── .env.example
│   ├── generic.pkr.hcl
│   ├── variables.global.pkr.hcl
│   └── config.plugins.pkr.hcl
├── linux/...
└── windows/...
```

The same workspace is consumed later by Terraform stacks that provision actual workloads.

Docs:

- HOWTO for first-time setup  
- Runbook for operations / failures  
- ADR-0016 describing the design  

GitHub: `[your-repo-link-here]`

If you’re running Proxmox and care about treating images as code, I’d be interested in how you’re doing it and what you’d change here.

---

## 3. Posting Plan (Packer vs SDN)

Because you already have SDN/Terraform posts planned, treat Packer as a **second wave** rather than dropping everything at once.

### 3.1 Suggested sequence

1. Run the **SDN/Terraform campaign first** (r/Proxmox, r/homelab, r/selfhosted, r/devops) over 1–2 weeks.
2. Watch which comments mention:
   - “How do you build your templates?”
   - “What base images are you using?”
3. Use those questions as a natural hook for the Packer posts.

Example timeline:

- Week 1: r/Proxmox SDN post.  
- Week 1–2: r/homelab + r/selfhosted SDN posts.  
- Week 2–3: r/devops SDN post.  
- Week 3–4: Start Packer posts:
  - r/Proxmox Packer post.
  - Then r/homelab / r/selfhosted.
  - Finally r/devops if there’s interest in the image pipeline angle.

### 3.2 Cross-linking

In the Packer posts, you can optionally add one short line:

> “This plugs into the same repo where I automated Proxmox SDN with Terraform – templates here, network there.”

And in SDN issues/comments, if someone asks about templates, link to the Packer section of the repo or the Packer Reddit post once it exists.

---

## 4. Pre-Post Checklist (Packer-specific)

Before you post about the Packer layer:

- [ ] All listed templates (Ubuntu, Rocky, Windows) **actually build** from `make` on a clean run.  
- [ ] `infra/packer-multi-os/README.md` is in sync with reality (templates, VMIDs, targets).  
- [ ] HOWTO + runbook links in the README work.  
- [ ] ADR-0016 is present and not obviously incomplete.  
- [ ] You’ve done at least one **fresh build** and used the resulting template for a VM.  
- [ ] GitHub repo is public and the Packer tree is easy to find from the root README.  

Once those are true, you can safely copy/paste the relevant draft into Reddit, swap `[your-repo-link-here]`, and post.

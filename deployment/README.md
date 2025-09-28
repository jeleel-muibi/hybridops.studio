# 🚀 Deployment Automation Suite

Welcome to the **Deployment Automation Suite** — your one-stop shop for deploying and managing infrastructure across multiple environments and platforms. This folder is organized for clarity, efficiency, and professional portfolio presentation.

---

## 📦 Structure Overview

```
deployment/
├── linux/        # Linux deployment scripts & tools
├── windows/      # Windows deployment scripts & tools
├── network/      # Network automation scripts
├── kubernetes/   # Kubernetes deployment scripts
├── inventory/    # Env-specific inventories/configs
├── common/       # Shared helpers/utilities
├── orchestrate_all.sh # Master orchestration script
└── README.md     # (this file)
```

- **Each folder** contains scripts targeting a specific platform or environment.
- **No per-folder READMEs:** This document is the central source of deployment documentation.
- **Every script** contains a detailed header at the top covering purpose, usage, arguments, examples, and author.

---

## 🛠️ Getting Started

### 1. Make Scripts Executable

```bash
chmod +x linux/*.sh network/*.sh kubernetes/*.sh common/*.sh orchestrate_all.sh
```
(Adjust for `*.ps1` or other extensions as needed.)

### 2. Run a Deployment Script

Navigate to the relevant subfolder and run the script, specifying the environment (`dev`, `staging`, `prod`, etc.):

```bash
cd linux
./deploy.sh dev
```

Or run the master orchestrator from the root:

```bash
./orchestrate_all.sh prod
```

> **Tip:** All scripts require the target environment as a command-line argument. If omitted, you'll see usage instructions from the script header.

---

## ⚙️ How It Works

- **Inventory Management:**
  Scripts use or generate inventory/config files from `inventory/` for the chosen environment.

- **Playbook & Script Execution:**
  Each deploy script (shell, PowerShell, etc.) executes the right automation playbooks (Ansible, etc.) and logic for the target platform.

- **Secrets/Vault Handling:**
  If using Ansible Vault or similar, you'll be prompted for secrets if needed. See each script header for specifics.

---

## ❓ Troubleshooting

- **Permission Denied:**
  Scripts must be executable:
  `chmod +x <script>`

- **Missing Arguments:**
  Scripts will exit and display usage instructions if required arguments are missing.

- **Other issues?**
  See the script header for dependencies, known issues, and advanced options.

---

## 🌟 Best Practices

- Use only these scripts for deployment to ensure all prerequisites and steps are followed.
- Source shared helpers from `common/` in your scripts as needed (see script headers).
- Keep code and documentation up to date. Update this README if the high-level structure changes.
- For any new script, include a standard header describing usage, author, and options.

---

## 📑 Related Documentation

- [Project Overview](../README.md)
- [Linux Automation](../linuxautomation/README.md)
- [Windows Automation](../windowsautomation/README.md)
- [Network Automation](../networkautomation/README.md)
- [Kubernetes Automation](../kubernetesautomation/README.md)
- [Inventory Management](../inventory/README.md)

---

## 👤 Author

Scripts and workflow by **Jeleel Muibi**
*Infrastructure Automation Specialist*

---

**For script-specific help,** always check the header at the top of the script!

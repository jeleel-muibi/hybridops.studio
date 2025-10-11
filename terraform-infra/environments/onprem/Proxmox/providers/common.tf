terraform {
  required_version = ">= 1.6.0"
  required_providers {
    proxmox    = { source = "Telmate/proxmox",      version = "~> 3.0"  }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.28" }
    helm       = { source = "hashicorp/helm",       version = "~> 2.13" }
    random     = { source = "hashicorp/random",     version = "~> 3.6"  }
    local      = { source = "hashicorp/local",      version = "~> 2.5"  }
    null       = { source = "hashicorp/null",       version = "~> 3.2"  }
    tls        = { source = "hashicorp/tls",        version = "~> 4.0"  }
  }
}

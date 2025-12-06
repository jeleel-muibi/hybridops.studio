// file: infra/terraform/modules/azure/aks/main.tf
// purpose: Provision an AKS cluster bound to an existing VNet subnet
// Maintainer: HybridOps.Studio
// date: 2025-11-29

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "environment" {
  type        = string
  description = "Logical environment name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group" {
  type        = string
  description = "Existing resource group name"
}

variable "vnet_name" {
  type        = string
  description = "Existing virtual network name"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for AKS node pool"
}

variable "kubernetes_version" {
  type        = string
  description = "AKS control plane version"
}

variable "node_count" {
  type        = number
  description = "Default node count"
}

variable "node_vm_size" {
  type        = string
  description = "VM size for AKS nodes"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "ho-${var.environment}-aks"
  location            = var.location
  resource_group_name = var.resource_group
  dns_prefix          = "ho-${var.environment}"

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name            = "system"
    node_count      = var.node_count
    vm_size         = var.node_vm_size
    vnet_subnet_id  = var.subnet_id
    orchestrator_version = var.kubernetes_version
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}

output "aks_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

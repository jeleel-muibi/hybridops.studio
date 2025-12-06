// file: infra/terraform/modules/azure/network/main.tf
// purpose: Provision Azure resource group and virtual network with subnets
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
  description = "Azure region for all resources"
}

variable "address_space" {
  type        = list(string)
  description = "VNet address space"
}

variable "kube_subnet_cidr" {
  type        = string
  description = "CIDR for AKS subnet"
}

variable "vm_subnet_cidr" {
  type        = string
  description = "CIDR for VM subnet"
}

resource "azurerm_resource_group" "rg" {
  name     = "ho-${var.environment}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "ho-${var.environment}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.address_space
}

resource "azurerm_subnet" "kube" {
  name                 = "kube"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.kube_subnet_cidr]
}

resource "azurerm_subnet" "vm" {
  name                 = "vm"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.vm_subnet_cidr]
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.vnet.name
}

output "kube_subnet_id" {
  description = "Subnet ID for AKS"
  value       = azurerm_subnet.kube.id
}

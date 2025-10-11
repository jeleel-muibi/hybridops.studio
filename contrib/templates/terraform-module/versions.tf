terraform {
  required_version = ">= 1.5.0"

  # Keep ONLY the provider(s) your module actually needs.
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

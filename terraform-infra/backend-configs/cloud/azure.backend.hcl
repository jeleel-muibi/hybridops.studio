# Remote state backend for Azure
# Create the resource group, storage account, and container beforehand.
resource_group_name  = "rg-hybridops-tf"
storage_account_name = "tfstatehybridops"
container_name       = "tfstate"
key                  = "cloud-azure.tfstate"

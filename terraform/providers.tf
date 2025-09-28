terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113" # latest stable as of 2025
    }
  }

  # Configure remote state backend (optional but recommended)
  # Replace with your storage account/container if you want shared state
  backend "azurerm" {
    resource_group_name  = "sf-mntr-rg"
    storage_account_name = "sfmntrtfstate"
    container_name       = "tfstate"
    key                  = "sf-mntr.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Used for getting tenant_id, subscription_id, etc.
data "azurerm_client_config" "current" {}

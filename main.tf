terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.81.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "raph-rg"
  location = "West Europe"
}

#DEPLOYER UN STORAGE ACCOUNT DANS VOTRE RESOURCE GROUP
#VOTRE STORAGE ACCOUNT DOIT ETRE EN "COOL"

resource "azurerm_storage_account" "sto" {
  name                     = "raphstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  access_tier              = "Cool"
}

resource "azurerm_storage_container" "container" {
  name                  = "vhds"
  storage_account_name  = azurerm_storage_account.sto.name
  container_access_type = "private"
}

# https://github.com/raphaeldeletoille/fdme

# terraform init
# terraform plan
# terraform apply 
# terraform apply -auto-approve
# terraform validate
# terraform destroy
# terraform fmt 

#DEPLOYER UN KEYVAULT SUR VOTRE RG
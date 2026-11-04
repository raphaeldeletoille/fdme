# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.12.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
  }
  subscription_id = "35ea0264-947c-4cb6-8919-4080d3f6232b"
}

resource "azurerm_resource_group" "rg" {
  name     = "raphaeld"
  location = "West Europe"
}

# resource "azurerm_resource_group" "rg" {
#   name     = "raphaeld2"
#   location = "West Europe"
# }

#DEPLOYER UN STORAGE ACCOUNT D ARCHIVES EN TERRAFORM (PAS COLD), PLUS FAIBLE REPLICATION.

#ALLER SUR L INTERFACE GRAPHIQUE (PORTAIL AZURE SUR GOOGLE) ET VERIFIER QUE VOTRE STORAGE EXISTE

resource "azurerm_storage_account" "storage" {
  name                     = "storageraphoqsjfq"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}

#DEPLOYER STORAGE CONTAINER DANS VOTRE STORAGE ACCOUNT, TENTEZ D UPLOAD DE LA DONNEES DANS VOTRE CONTAINER
resource "azurerm_storage_container" "container" {
  name                  = "vhds"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

#DEPLOYER UN KEYVAULT EN MODE ACCESS POLICY DANS VOTRE RG

#DEPLOYER UN SECRET DANS VOTRE KEYVAULT
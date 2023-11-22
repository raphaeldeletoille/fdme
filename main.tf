terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
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
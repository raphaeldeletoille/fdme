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

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = "raphkv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id # = 68a63944-3750-446d-855d-3691acf10ab8

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

#DEPLOYER UN SECRET DANS VOTRE KEYVAULT 
resource "azurerm_key_vault_secret" "mdp" {
  name         = "mdpdatabase"
  value        = "qIQHFh87-!$$"
  key_vault_id = azurerm_key_vault.kv.id
}

#GENEREZ UN MOT DE PASSE ALEATOIRE POUR REMPLACER LA VALUE DE VOTRE SECRET 

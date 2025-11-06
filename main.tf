terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.51.0"
    }
  }
}

provider "azurerm" {
    features {
    }
    subscription_id = "556b3479-49e0-4048-ace9-9b100efe5b6d"
}

resource "azurerm_resource_group" "rg" {
  name     = "raphaeld"
  location = "West Europe"
}

#DEPLOYER UN STORAGE ACCOUNT EN "COOL"
resource "azurerm_storage_account" "storage" {
  name                     = "raphstoojsdf"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}


#DEPLOYER UN CONTAINER DANS VOTRE STORAGE ACCOUNT // ET INSTALLER AZURE STORAGE EXPLORER
resource "azurerm_storage_container" "container" {
  name                  = "vhds"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

#CREER UN SAS TOKEN ET VOUS CONNECTER A VOTRE CONTAINER (Terraform)
#DEPUIS AZURE STORAGE EXPLORER ET DEPOSER UN FICHIER TEXTE (Azure Storage Explorer)
data "azurerm_storage_account_sas" "sas" {
    connection_string = azurerm_storage_account.storage.primary_connection_string
    https_only           = true

    resource_types {
        service   = true
        container = true
        object    = true
    }

    services {
        blob  = true
        queue = true
        table = true
        file  = true
    }

    start  = "2025-03-21T00:00:00Z"
    expiry = "2026-03-21T00:00:00Z"

    permissions {
        read    = true
        write   = true
        delete  = true
        list    = true
        add     = true
        create  = true
        update  = true
        process = true
        tag     = true
        filter  = true
    }
}


output "container_sas_url" {
    value       = nonsensitive("${azurerm_storage_account.storage.primary_blob_endpoint}${data.azurerm_storage_account_sas.sas.sas}")
    sensitive   = false
}


#DEPLOYER UN KEYVAULT EN MODE ACCESS POLICY, DE VOUS DONNER (A VOUS MEME) tous les droits "Secret" et créer un Secret.
#ALLER VOIR SUR L INTERFACE GRAPHIQUE VOTRE SECRET (MDP)

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = "raphkvoijqs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}

resource "azurerm_key_vault_access_policy" "kv_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]
}

resource "azurerm_key_vault_secret" "mdp" {
  name         = "secret-sauce"
  value        = "szechuan"
  key_vault_id = azurerm_key_vault.kv.id
  depends_on = [azurerm_key_vault_access_policy.kv_access]
}

#DEPLOYER UN MSSQL SERVER EN TERRAFORM ET LUI DONNER LE MDP DU KEYVAULT EN TANT QUE PASSWORD en france central

#DEPLOYER 1 VIRTUAL NETWORK ET DEPLOYER 3 SUBNETS (LES 3 SUBNETS DOIVENT ETRE DEPLOYEES A PARTIR D UN SEUL BLOC 
#EN UTILISANT COUNT)

resource "azurerm_virtual_network" "vnet" {
  name                = "raph-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnets" {
  count = 3
  
  name                 = "raph-subnet${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.${count.index}.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}
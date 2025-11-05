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
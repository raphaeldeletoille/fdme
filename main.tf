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

# DESTROY COMPLETE
# INSTALLER TERRAFORM / AZ CLI / VSCODE 
# AUTHENTIFIER VOUS AVEC AZ LOGIN
# MAIN.TF


data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = "raphkvioqsujf"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name # = "raphaeld"
  rbac_authorization_enabled = false
  tenant_id                  = data.azurerm_client_config.current.tenant_id # = "fbd5b602-423c-4722-be67-8382bc9dc8fa"
  sku_name                   = "premium"
}

#object ID = ID unique d'un compte user ou d'un groupe
resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]
}

resource "azurerm_key_vault_secret" "mdpVM" {
  name         = "sdfpldsqlkgfkoijsdf"
  value        = random_password.mdpVM.result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "mdpSQL" {
  name         = "iuezarfiojqzsofijodzsf"
  value        = "qsdfkjqfkq675"
  key_vault_id = azurerm_key_vault.kv.id
}



#GENERER UN MDP ALEATOIRE DANS VOTRE VALEUR DE SECRET (VOTRE VALEUR DE MDP NE DOIT PAS ETRE EN CLAIR DANS VOTRE CODE)
resource "random_password" "mdpVM" {
  length           = 17
  special          = true
  min_numeric      = 3
  override_special = "!"
}

#VIRTUAL NETWORK (VNET) 
#SUBNET 

#UNE VM ATTEND UN SUBNET

# FAIRE CELA EN TERRAFORM
# DEPLOYER 1 VNET
# DEPLOYER 3 SUBNETS DANS CE VNET

resource "azurerm_virtual_network" "vnet" {
  name                = "raph-vnetnetwork"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

#DEPLOYER VOS 3 SUBNETS A PARTIR D UN SEUL BLOC. UTILISER COUNT
resource "azurerm_subnet" "subnets" {
  count = 3

  name                 = "raph-subnet${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.${count.index}.0/24"]
}


#CONNECTER VOTRE KEYVAULT A VOTRE SUBNET 0

# UTILISER UNIQUEMENT CE TYPE DE BLOC "private endpoint"
resource "azurerm_private_endpoint" "pe-kv" {
  name                = "raph-endpoint-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnets[0].id

  private_service_connection {
    name                           = "raph-connection-kv"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}

# ALLOW PUBLIC ENDPOINT KEYVAULT ONLY FROM YOUR OWN PUBLIC IP
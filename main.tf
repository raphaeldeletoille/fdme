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
  name                     = "raphstorageuhqsfd"
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

# resource "azurerm_key_vault" "kv" {
#   name                        = "raphkv"
#   location                    = azurerm_resource_group.rg.location
#   resource_group_name         = azurerm_resource_group.rg.name
#   enabled_for_disk_encryption = true
#   tenant_id                   = data.azurerm_client_config.current.tenant_id
#   soft_delete_retention_days  = 7
#   purge_protection_enabled    = false

#   sku_name = "standard"

#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = data.azurerm_client_config.current.object_id # = 68a63944-3750-446d-855d-3691acf10ab8

#     key_permissions = [
#       "Get",
#     ]

#     secret_permissions = [
#       "Set",
#       "Get",
#       "Delete",
#       "Purge",
#       "Recover"
#     ]

#     storage_permissions = [
#       "Get",
#     ]
#   }
# }

#DEPLOYER UN SECRET DANS VOTRE KEYVAULT 
# resource "azurerm_key_vault_secret" "mdp" {
#   name         = "mdpdatabase"
#   value        = random_password.password.result
#   key_vault_id = azurerm_key_vault.kv.id
# }

#GENEREZ UN MOT DE PASSE ALEATOIRE POUR REMPLACER LA VALUE DE VOTRE SECRET 
resource "random_password" "password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 1
}

#DEPLOYEZ UN MSSQL SERVER DANS MON RESOURCE GROUP "raph-rg" (POU CELA BESOIN D UN DATASOURCE)
#ET LE MDP ADMIN SERA LE MDP DANS VOTRE SECRET

resource "azurerm_mssql_server" "sqlsrv" {
  name                         = "raphsqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "missadministrator"
  administrator_login_password = random_password.password.result
  minimum_tls_version          = "1.2"

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }
}


# DEPLOYER UN MSSQL DATABASE SUR VOTRE MSSQL SERVER
# LE SKU_NAME = GP_S_Gen5_2

resource "azurerm_mssql_database" "sqldb" {
  name                        = "acctest-db-d"
  server_id                   = azurerm_mssql_server.sqlsrv.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb                 = 4
  min_capacity                = 1
  read_scale                  = false
  sku_name                    = "GP_S_Gen5_2"
  zone_redundant              = true
  auto_pause_delay_in_minutes = 60
}

#DEPLOYER 3 VIRTUAL NETWORK A PARTIR DU MEME BLOC (COUNT)

resource "azurerm_virtual_network" "vnet" {
  count               = 3
  name                = "raph-network${count.index}" 
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.${count.index}.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

# DEPLOYER 2 SUBNETS (UN BLOC AZURERM_SUBNET) AVEC COUNT 
# DANS VOTRE VNET 0

resource "azurerm_subnet" "subnet" {
  count                = 2
  name                 = "subnet${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[0].name 
  address_prefixes     = ["10.0.${count.index}.0/24"]
}


#PRIVATE ENDPOINT
#BRANCHER VOTRE SQL A VOTRE DERNIER SUBNET

resource "azurerm_private_endpoint" "cartereseau" {
  name                = "sqlsrv-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet[1].id

  private_service_connection {
    name                           = "sqlsrv-connection"
    private_connection_resource_id = azurerm_mssql_server.sqlsrv.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
}

#DEPLOYER UNE VM (LINUX OU WINDOWS SERVER) 
#CETTE VM VOUS LA CONNECTEZ A VOTRE SUBNET 2
#CONNECTEZ VOUS A VOTRE VM

SKU = Standard_B1ms
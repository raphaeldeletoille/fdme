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

# size = 

resource "azurerm_public_ip" "ippublic" {
  name                = "vmraphpublic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "networkcard" {
  name                = "raph-vm-card"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet[1].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ippublic.id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "raph-machine"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1ms"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.networkcard.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

#FOR_EACH (MAP OBJECT)

#DEPLOYER 2 RESOURCE GROUP AVEC FOR_EACH DEPUIS UN SEUL BLOC
#LE 1ER RG DOIT UTILISER LA LOCATION West Europe, LE 2eme doit utiliser West US


resource "azurerm_resource_group" "all_rg" {
  for_each = var.all_rg

  name     = each.value.name
  location = each.value.location
}

# 1) #DEPLOYER UN LOG ANALYTICS DANS VOTRE RESOURCE GROUP WEST EUROPE (QUI A ETE DEPLOYE AVEC LE FOR EACH)

# 2) #ENVOYEZ LES LOGS DE VOTRE STORAGE ACCOUNT VERS VOTRE LOG ANALYTICS 


resource "azurerm_log_analytics_workspace" "toto" {
  name                = "toto-acctest-01"
  location            = azurerm_resource_group.all_rg["rg1"].location
  resource_group_name = azurerm_resource_group.all_rg["rg1"].name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#DONNEZ LES DROITS READER A L UTILISATEUR jgrandidier (jgrandidier@deletoilleprooutlook.onmicrosoft.com) sur votre RGcheck "name" {
  
data "azuread_user" "leboss" {
  user_principal_name = "jgrandidier@deletoilleprooutlook.onmicrosoft.com"
}

resource "azurerm_role_assignment" "donner_permission" {
  scope                = azurerm_resource_group.rg.id 
  role_definition_name = "Reader"
  principal_id         = data.azuread_user.leboss.object_id
}

#DEPLOYER UN GRAFANA DASHBOARD
#DONNER LES PERMISSIONS A L IDENTITE DE GRAFANA SUR VOTRE LOG ANALYTICS (MONITORING READER)
#DONNER LES PERMISSIONS A VOTRE UTILISATEUR SUR GRAFANA (Grafana Admin)

resource "azurerm_dashboard_grafana" "grafana" {
  name                              = "grafana-dg"
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = "West Europe"
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true

  identity {
    type = "SystemAssigned"
  }
}

output "identity_grafana" {
  value = azurerm_dashboard_grafana.grafana.identity
}

resource "azurerm_role_assignment" "donner_permission_grafana_user" {
  scope                = azurerm_dashboard_grafana.grafana.id 
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "donner_permission_grafana_log_analytics" {
  scope                = azurerm_log_analytics_workspace.toto.id 
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity[0].principal_id
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
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
  https_only        = true

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
  value     = nonsensitive("${azurerm_storage_account.storage.primary_blob_endpoint}${data.azurerm_storage_account_sas.sas.sas}")
  sensitive = false
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
}

#DEPLOYER VOTRE KEYVAULT DANS VOTRE PREMIER SUBNET A L AIDE D UN PRIVATE ENDPOINT

resource "azurerm_private_endpoint" "kvcard" {
  name                = "raph-endpoint-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnets[0].id

  private_service_connection {
    name                           = "raph-endpoint-kv-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}

### Deployer une VM (WINDOWS SERVER OU UBUNTU) avec la vm size = Standard_B2as_v2
### DEPLOYER CETTE VM DANS VOTRE PREMIER SUBNET
### MODE LOGIN PASSWORD ET VOTRE PASSWORD DOIT ETRE VOTRE SECRET KEYVAULT


resource "azurerm_network_interface" "vmcard" {
  name                = "raph-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "raph-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2as_v2"
  admin_username      = "adminuser"
  admin_password      = azurerm_key_vault_secret.mdp.value
  network_interface_ids = [
    azurerm_network_interface.vmcard.id,
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

#CONNECTEZ VOUS A VOTRE VM (SANS UTILISER BASTION)

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "raph-vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vmcard.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_public_ip" "publicip" {
  name                = "raphIP"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

#REMPLACER VOTRE SECRET (VOTRE MDP) PAR UN MDP ALEATOIRE AVEC 10 CARAC AU MINIMUM ET 1 CARAC SPECIAL MINIMUM ET 1 MAJ MIN 
#ET 1 CHIFFRE MIN
#NE PAS METTRE DE MDP EN CLAIR DANS VOTRE CODE
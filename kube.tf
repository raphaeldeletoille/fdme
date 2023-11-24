resource "azurerm_kubernetes_cluster" "kube" {
  name                = "raph-aks1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "raphaks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_container_registry" "acr" {
  name                = "raphregistry"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = false
  georeplications {
    location                = "North Europe"
    zone_redundancy_enabled = true
    tags                    = {}
  }
}

# az acr build --registry raphregistry --image aks-store-demo/product-service:latest ./src/product-service/
# az acr build --registry raphregistry --image aks-store-demo/order-service:latest ./src/order-service/
# az acr build --registry raphregistry --image aks-store-demo/store-front:latest ./src/store-front/
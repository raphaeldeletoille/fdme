resource "azurerm_resource_group" "rg" {
  name     = var.prenom
  location = "West Europe"
}

#RECUPER KEYVAULT, SECRET, LOG ANALYTICS WORKSPACE (LE VOTRE)
#DIAGNOSTIC SETTING DE VOTRE KV VERS LE LOG ANALYTICS
#GRAFANA

resource "azurerm_dashboard_grafana" "grafana" {
  name                  = "${var.prenom}-grafana"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  grafana_major_version = 13
  sku                   = "Standard"
  sku_size              = "X1"

  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "grafana_admin" {
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity[0].principal_id
}

output "grafana_url" {
  description = "URL Azure Managed Grafana"
  value       = azurerm_dashboard_grafana.grafana.endpoint
}



# #CREER UNE ALERTE POUR ETRE INFORME SI QUELQU UN SANS AUTORISATION TENTE D ACCEDER A UN SECRET KV
#   criteria {
#     query = <<-KQL
#       AzureDiagnostics
#       | where ResourceProvider == "MICROSOFT.KEYVAULT"
#       | where _ResourceId =~ "${azurerm_key_vault.kv.id}"
#       | where Category == "AuditEvent"
#       | where OperationName =~ "SecretGet"
#       | where ResultSignature == "403" or ResultType =~ "Forbidden"
#     KQL
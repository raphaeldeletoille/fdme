data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rgexterne" {
  name = "cecinestpasmonrg"
}

output "id" {
  value = data.azurerm_resource_group.rgexterne.id
}

data "azurerm_log_analytics_workspace" "CECINESTPASMONLOGANALYTICS" {
  name                = "LogAnalytics"
  resource_group_name = "cecinestpasmonrg"
}

data "azurerm_monitor_diagnostic_categories" "categories" {
  resource_id = azurerm_virtual_network.vnet.id
}

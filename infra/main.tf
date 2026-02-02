resource "azurerm_resource_group" "main" {
  name = "${var.project_name}-${var.environment}-rg"
  location = "${var.location}"
}

resource "azurerm_service_plan" "my_plan" {
  name = "${var.project_name}-${var.environment}-asp"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  os_type = "Linux"
  sku_name = "B1" 
}

resource "azurerm_storage_account" "main" {
  name = "${replace(var.project_name, "-", "")}${var.environment}sa"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "file_storage" {
  name = "order${var.environment}st"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  account_tier        = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "receipts" {
  name                  = "receipts"
  storage_account_id = azurerm_storage_account.main.id
  container_access_type = "private"
}
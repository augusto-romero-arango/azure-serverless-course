resource "azurerm_linux_function_app" "order_tracker_func" {
  name                = "${var.project_name}-order-tracker-func-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_app_service_plan.my_plan.id

  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  site_config {
    application_stack {
      node_version = "20"
    }
  }

  app_settings = { 
    FUNCTIONS_WORKER_RUNTIME = "node"
    AzureWebJobsStorage    = azurerm_storage_account.main.primary_connection_string
   }

}

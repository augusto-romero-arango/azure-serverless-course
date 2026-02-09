resource "azurerm_linux_function_app" "order_tracker_func" {
  name                = "${var.project_name}-order-tracker-func-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.my_plan.id

  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  site_config {
    application_stack {
      node_version = "20"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "node"
    AzureWebJobsStorage      = azurerm_storage_account.main.primary_connection_string

    APPINSIGHTS_INSTRUMENTATIONKEY             = azurerm_application_insights.order_tracker_ai.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING      = azurerm_application_insights.order_tracker_ai.connection_string
    APPLICATIONINSIGHTSAGENT_EXTENSION_VERSION = "~3"

    CosmosDbConnectionString  = azurerm_cosmosdb_account.main.primary_sql_connection_string
    CosmosDbName      = azurerm_cosmosdb_sql_database.order_db.name
    CosmosDbContainer = azurerm_cosmosdb_sql_container.orders.name
  }

}

resource "azurerm_application_insights" "order_tracker_ai" {
  name                = "order-tracker-ai-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "other"

  workspace_id = azurerm_log_analytics_workspace.main.id

}


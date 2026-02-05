resource "azurerm_linux_function_app" "order_process" {
  name = "order-processor-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  service_plan_id = azurerm_service_plan.my_plan.id

    storage_account_name = azurerm_storage_account.main.name
    storage_account_access_key = azurerm_storage_account.main.primary_access_key
    
  site_config {
    application_stack {
      dotnet_version = "9.0"
      use_dotnet_isolated_runtime = true
    }
  }

  app_settings = { 
        FUNCTIONS_WORKER_RUNTIME =  "dotnet-isolated"
        AzureWebJobsStorage = azurerm_storage_account.main.primary_connection_string
        blobContainerName = azurerm_storage_container.receipts.name
        WEBSITE_RUN_FROM_PACKAGE = "1"

        APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.order_processor_ai.instrumentation_key
        APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.order_processor_ai.connection_string
        APPLICATIONINSIGHTSAGENT_EXTENSION_VERSION = "~3"

        SERVICE_BUS_CONNECTION_STRING = azurerm_servicebus_namespace_authorization_rule.listen_rule.primary_connection_string



        ReceiptStorageConnectionString = azurerm_storage_account.file_storage.primary_connection_string
    }
}

resource "azurerm_application_insights" "order_processor_ai" {
  name                = "order-processor-ai-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "other"

  workspace_id = azurerm_log_analytics_workspace.main.id
  
}

resource "azurerm_servicebus_namespace_authorization_rule" "listen_rule" {
  name = "listen_rule"
  namespace_id = azurerm_servicebus_namespace.namespace.id
    
  listen = true

}
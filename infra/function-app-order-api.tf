resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = "30"
}

resource "azurerm_application_insights" "app_insights" {
    name                = "${var.project_name}-api-${var.environment}-ai"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    application_type    = "other"
    workspace_id = azurerm_log_analytics_workspace.main.id
    tags = { 
        "func" =  "${var.project_name}-api-${var.environment}"  
        }
  
}

resource "azurerm_linux_function_app" "order-api-func" {
    name = "${var.project_name}-api-${var.environment}-func"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    service_plan_id = azurerm_service_plan.my_plan.id
    
    storage_account_name = azurerm_storage_account.main.name
    storage_account_access_key = azurerm_storage_account.main.primary_access_key

  site_config { 
    application_stack {
        python_version = "3.11"
    }
  }
  
  app_settings = { 
    FUNCTIONS_WORKER_RUNTIME = "python"
    AzureWebJobsStorage = azurerm_storage_account.main.primary_connection_string 
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.app_insights.instrumentation_key

    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.app_insights.connection_string
    APPLICATIONINSIGHTSAGENT_EXTENSION_VERSION = "~3"
  }

  tags = { 
        "func" =  "${var.project_name}-api-${var.environment}"  
        }
}

data "azurerm_monitor_diagnostic_categories" "func" {
  resource_id = azurerm_linux_function_app.order-api-func.id
}

locals {
  desired_logs = toset([
    "FunctionAppLogs",
    "AppServiceConsoleLogs",
    "AppServiceAppLogs",
    "AppServiceHTTPLogs",
    "AppServicePlatformLogs"
  ])

  available_logs = toset(data.azurerm_monitor_diagnostic_categories.func.azurerm_monitor_diagnostic_categories[*].name)
  enabled_logs = setintersection(local.desired_logs, local.available_logs)

  desired_metrics = toset([
    "AllMetrics"
  ])
  available_metrics = toset(data.azurerm_monitor_diagnostic_categories.func.azurerm_monitor_diagnostic_categories[*].name)
  enabled_metrics = setintersection(local.desired_metrics, local.available_metrics)


}

resource "azurerm_monitor_diagnostic_setting" "func_to_law" {
  name = "${var.project_name}-api-${var.environment}-func-diag"
  target_resource_id = azurerm_linux_function_app.order-api-func.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  dynamic "enabled_log" {
    for_each = local.enabled_logs
    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_metric" {
    for_each = local.enabled_metrics
    content {
      category = enabled_metric.value
    }
  }

}

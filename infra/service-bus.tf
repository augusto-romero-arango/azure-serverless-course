resource "azurerm_servicebus_namespace" "namespace" {
  name= "${var.project_name}-${var.environment}-sbns"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku = "Standard"
}

resource "azurerm_servicebus_queue" "order_queue" {
  name = "notifications-queue"
  namespace_id = azurerm_servicebus_namespace.namespace.id
  forward_dead_lettered_messages_to = azurerm_servicebus_queue.dlq.name

  max_delivery_count = 5
}

resource "azurerm_servicebus_queue" "dlq" {
  name = "notifications-dlq"
  namespace_id = azurerm_servicebus_namespace.namespace.id
}

resource "azurerm_servicebus_namespace_authorization_rule" "auth_rule" {
  name = "send_policy"
  namespace_id = azurerm_servicebus_namespace.namespace.id

  send = true
}

resource "azurerm_monitor_action_group" "ops" {
  name = "${var.project_name}-ops-${var.environment}-ag"
  resource_group_name = azurerm_resource_group.main.name
  short_name = "ops"

  email_receiver {
    name = "email_dlq_alerts"
    email_address = "augromara@gmail.com"
    
    }
}

resource "azurerm_monitor_metric_alert" "alert_dlq" {
  name = "${var.project_name}-${var.environment}-dlq-ag"
  resource_group_name = azurerm_resource_group.main.name
  scopes = [azurerm_servicebus_namespace.namespace.id]
  description = "Alert for dead lettered messages in Service Bus Queue"
  severity = 2
  frequency = "PT1M"
  window_size = "PT5M"
  enabled = true
  target_resource_type = "Microsoft.ServiceBus/namespaces"
  target_resource_location = azurerm_resource_group.main.location

  criteria {
    metric_namespace = "Microsoft.ServiceBus/namespaces"
    metric_name = "DeadletteredMessages"
    aggregation = "Maximum"
    operator = "GreaterThan"
    threshold = 0
  
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  } 
}


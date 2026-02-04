resource "azurerm_servicebus_namespace" "namespace" {
  name= "${var.project_name}-${var.environment}-sbns"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku = "Standard"
}

resource "azurerm_servicebus_queue" "order_queue" {
  name = "notifications-queue"
  namespace_id = azurerm_servicebus_namespace.namespace.id
  max_delivery_count = 5
}

resource "azurerm_servicebus_namespace_authorization_rule" "auth_rule" {
  name = "send_policy"
  namespace_id = azurerm_servicebus_namespace.namespace.id

  send = true
}
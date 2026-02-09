resource "azurerm_eventgrid_event_subscription" "file_uploaded" {
  name  = "file-uploaded-subscription-${var.environment}"
  scope = azurerm_storage_account.file_storage.id

  included_event_types = ["Microsoft.Storage.BlobCreated"]

  azure_function_endpoint {
    function_id                       = "${azurerm_linux_function_app.order_tracker_func.id}/functions/OrderTrackerFunction"
    max_events_per_batch              = 1
    preferred_batch_size_in_kilobytes = 64
  }
  retry_policy {
    max_delivery_attempts = 5
    event_time_to_live    = 1440
  }
  depends_on = [azurerm_linux_function_app.order_tracker_func]
}

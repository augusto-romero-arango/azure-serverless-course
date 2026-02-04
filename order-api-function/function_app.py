import azure.functions as func
import datetime
import json
import logging
import os
from helpers import validate_order
from azure.servicebus import ServiceBusClient, ServiceBusMessage


app = func.FunctionApp()

@app.route(route="orderTrigger", methods=["POST"], auth_level=func.AuthLevel.FUNCTION)
def order_trigger(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Processing a new order.")

    try:
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse(
            "Invalid request body.",
            status_code=400
        )

    is_valid, message = validate_order(req_body)
    if not is_valid:
        return func.HttpResponse(
            json.dumps({"error": message}),
            mimetype="application/json",
            status_code=400
        )

    connection_str = os.getenv("SERVICE_BUS_CONNECTION_STRING")
    queue_name =os.getenv("SERVICE_BUS_QUEUE_NAME")

    try:
        with ServiceBusClient.from_connection_string(connection_str) as client:
            with client.get_queue_sender(queue_name) as sender:
                order_message = ServiceBusMessage(json.dumps(req_body))
                sender.send_messages(order_message)

    
        return func.HttpResponse(
            json.dumps({"message": "Order processed successfully."}),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"Error processing order: {e}")
        return func.HttpResponse(
            json.dumps({"Service bus issue:": str(e)}),
            mimetype="application/json",
            status_code=500
        )

    
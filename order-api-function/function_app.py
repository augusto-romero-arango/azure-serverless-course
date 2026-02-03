import azure.functions as func
import datetime
import json
import logging
from helpers import validate_order

app = func.FunctionApp()

@app.route(route="orderTrigger", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
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

    return func.HttpResponse(
        json.dumps({"message": "Order processed successfully."}),
        mimetype="application/json",
        status_code=200
    )
    
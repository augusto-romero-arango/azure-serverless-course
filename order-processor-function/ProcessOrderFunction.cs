using System;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace order_processor_function;

public class ProcessOrderFunction
{
    private readonly ILogger<ProcessOrderFunction> _logger;

    public ProcessOrderFunction(ILogger<ProcessOrderFunction> logger)
    {
        _logger = logger;
    }

    [Function(nameof(ProcessOrderFunction))]
    public async Task Run(
        [ServiceBusTrigger("notifications-queue", Connection = "SERVICE_BUS_CONNECTION_STRING")]
        ServiceBusReceivedMessage message,
        ServiceBusMessageActions messageActions)
    {
        _logger.LogInformation("Message ID: {id}", message.MessageId);
        _logger.LogInformation("Message Body: {body}", message.Body);
        _logger.LogInformation("Message Content-Type: {contentType}", message.ContentType);

        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        };
        var orderInfo = JsonSerializer.Deserialize<OrderModel>(message.Body.ToString(), options);

        var orderDetailInfo = $@"Order Details:
            Customer Name: {orderInfo.CustomerName}
            Email: {orderInfo.Email}
            Order Date: {orderInfo.OrderDate}
            Order Amount: {orderInfo.OrderAmount}
            Items:";

        foreach (var item in orderInfo.Items)
        {
            orderDetailInfo += $@"
                Product ID: {item.ProductId}, Quantity: {item.Quantity}"+Environment.NewLine;
        }

        var blobContainerName = Environment.GetEnvironmentVariable("BlobContainerName");
        var blobConnectionString = Environment.GetEnvironmentVariable("ReceiptStorageConnectionString");

        var blobServiceClient = new Azure.Storage.Blobs.BlobServiceClient(blobConnectionString);
        var blobContainerClient = blobServiceClient.GetBlobContainerClient(blobContainerName);
        await blobContainerClient.CreateIfNotExistsAsync();

        var blobName = $"order-{orderInfo.CustomerName}-{DateTime.Now.ToString("yyyyMMddHHmmss")}.txt";
        var blobClient = blobContainerClient.GetBlobClient(blobName);
        
        using (var stream = new MemoryStream(Encoding.UTF8.GetBytes(orderDetailInfo)))
        {
            await blobClient.UploadAsync(stream);
        }

        // Complete the message
        await messageActions.CompleteMessageAsync(message);
    }

    
}

public class OrderModel
{
    public string CustomerName { get; set; }   
    public string Email { get; set; }   
    public string OrderDate { get; set; }   
    public double OrderAmount { get; set; }   
    public OrderItem[] Items { get; set; }   
}

public class OrderItem
{
    public string ProductId { get; set; }
    public int Quantity { get; set; }   

}
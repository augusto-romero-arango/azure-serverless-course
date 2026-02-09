const { app } = require('@azure/functions');
const { CosmosClient } = require('@azure/cosmos');

const cosmosClient = new CosmosClient(process.env.CosmosDbConnectionString);
const db = cosmosClient.database(process.env.CosmosDbName);
const container = db.container(process.env.CosmosDbContainer);


app.eventGrid('OrderTrackerFunction', {
    handler: async (event, context) => {
        context.log('Event grid function processed event:', event);

        if (event.eventType === 'Microsoft.Storage.BlobCreated') {
            const blobUrl = event.data.url;
            const timestamp = event.eventTime;

            const orderRecordDoc = {
                id: `record-${Date.now()}`,
                recordUrl: blobUrl,
                status: 'Completed',
                timestamp: timestamp

            };

            try {
                await container.items.create(orderRecordDoc);
                context.log('Order record added in Cosmos DB');
            } catch (error) {
                context.log.error('Error adding order record to Cosmos DB:', error);
            }


        }
        else {
            context.log('Unhandled event type:', event.eventType);
        }
    }
});

global class VehicleOrderBatch
    implements Database.Batchable<sObject> {

    global Database.QueryLocator start(
        Database.BatchableContext bc
    ) {
        return Database.getQueryLocator([
            SELECT Id, Status__c, Vehicle__c
            FROM Vehicle_Order__c
            WHERE Status__c = 'Pending'
            AND Vehicle__c != null
        ]);
    }

    global void execute(
        Database.BatchableContext bc,
        List<Vehicle_Order__c> orderList
    ) {
        Set<Id> vehicleIds = new Set<Id>();

        for (Vehicle_Order__c orderRec : orderList) {
            vehicleIds.add(orderRec.Vehicle__c);
        }

        Map<Id, Vehicle__c> vehicleStockMap =
            new Map<Id, Vehicle__c>([
                SELECT Id, Stock_Quantity__c
                FROM Vehicle__c
                WHERE Id IN :vehicleIds
                FOR UPDATE
            ]);

        List<Vehicle_Order__c> ordersToUpdate =
            new List<Vehicle_Order__c>();

        Map<Id, Integer> remainingStock =
            new Map<Id, Integer>();

        for (Vehicle__c vehicle : vehicleStockMap.values()) {
            Integer qty = vehicle.Stock_Quantity__c == null
                ? 0
                : Integer.valueOf(vehicle.Stock_Quantity__c);
            remainingStock.put(vehicle.Id, qty);
        }

        for (Vehicle_Order__c orderRec : orderList) {
            Integer stock = remainingStock.get(orderRec.Vehicle__c);

            if (stock != null && stock > 0) {
                orderRec.Status__c = 'Confirmed';
                ordersToUpdate.add(orderRec);
                remainingStock.put(orderRec.Vehicle__c, stock - 1);
            }
        }

        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Vehicle order batch job completed.');
    }
}

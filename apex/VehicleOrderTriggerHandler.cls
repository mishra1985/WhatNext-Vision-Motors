public class VehicleOrderTriggerHandler {

    public static void handleTrigger(
        List<Vehicle_Order__c> newOrders,
        Map<Id, Vehicle_Order__c> oldOrders,
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        if (isBefore && (isInsert || isUpdate)) {
            preventOrderIfOutOfStock(newOrders);
        }

        if (isAfter && (isInsert || isUpdate)) {
            updateStockOnOrderPlacement(
                newOrders, oldOrders, isInsert, isUpdate
            );
        }
    }

    private static void preventOrderIfOutOfStock(
        List<Vehicle_Order__c> orders
    ) {
        Set<Id> vehicleIds = new Set<Id>();

        for (Vehicle_Order__c orderRec : orders) {
            if (orderRec.Vehicle__c != null &&
                orderRec.Status__c == 'Confirmed') {
                vehicleIds.add(orderRec.Vehicle__c);
            }
        }

        if (vehicleIds.isEmpty()) return;

        Map<Id, Vehicle__c> vehicleStockMap =
            new Map<Id, Vehicle__c>([
                SELECT Id, Stock_Quantity__c
                FROM Vehicle__c
                WHERE Id IN :vehicleIds
            ]);

        for (Vehicle_Order__c orderRec : orders) {
            Vehicle__c vehicle =
                vehicleStockMap.get(orderRec.Vehicle__c);

            if (vehicle != null &&
                (vehicle.Stock_Quantity__c == null ||
                 vehicle.Stock_Quantity__c <= 0)) {
                orderRec.addError(
                    'This vehicle is out of stock. Order cannot be placed.'
                );
            }
        }
    }

    private static void updateStockOnOrderPlacement(
        List<Vehicle_Order__c> orders,
        Map<Id, Vehicle_Order__c> oldOrders,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        Set<Id> vehicleIds = new Set<Id>();

        for (Vehicle_Order__c orderRec : orders) {
            Boolean newlyConfirmed = false;

            if (isInsert) {
                newlyConfirmed =
                    orderRec.Status__c == 'Confirmed';
            } else if (isUpdate) {
                Vehicle_Order__c oldOrder =
                    oldOrders.get(orderRec.Id);

                newlyConfirmed =
                    orderRec.Status__c == 'Confirmed' &&
                    oldOrder.Status__c != 'Confirmed';
            }

            if (newlyConfirmed &&
                orderRec.Vehicle__c != null) {
                vehicleIds.add(orderRec.Vehicle__c);
            }
        }

        if (vehicleIds.isEmpty()) return;

        Map<Id, Vehicle__c> vehicleStockMap =
            new Map<Id, Vehicle__c>([
                SELECT Id, Stock_Quantity__c
                FROM Vehicle__c
                WHERE Id IN :vehicleIds
                FOR UPDATE
            ]);

        Map<Id, Integer> quantityRequired =
            new Map<Id, Integer>();

        for (Vehicle_Order__c orderRec : orders) {
            Boolean newlyConfirmed = false;

            if (isInsert) {
                newlyConfirmed =
                    orderRec.Status__c == 'Confirmed';
            } else if (isUpdate) {
                Vehicle_Order__c oldOrder =
                    oldOrders.get(orderRec.Id);

                newlyConfirmed =
                    orderRec.Status__c == 'Confirmed' &&
                    oldOrder.Status__c != 'Confirmed';
            }

            if (newlyConfirmed &&
                orderRec.Vehicle__c != null) {
                Integer count =
                    quantityRequired.containsKey(orderRec.Vehicle__c)
                    ? quantityRequired.get(orderRec.Vehicle__c)
                    : 0;

                quantityRequired.put(
                    orderRec.Vehicle__c, count + 1
                );
            }
        }

        List<Vehicle__c> vehiclesToUpdate =
            new List<Vehicle__c>();

        for (Id vehicleId : quantityRequired.keySet()) {
            Vehicle__c vehicle =
                vehicleStockMap.get(vehicleId);
            Integer required =
                quantityRequired.get(vehicleId);

            if (vehicle != null &&
                vehicle.Stock_Quantity__c != null &&
                vehicle.Stock_Quantity__c >= required) {
                vehicle.Stock_Quantity__c -= required;
                vehiclesToUpdate.add(vehicle);
            }
        }

        if (!vehiclesToUpdate.isEmpty()) {
            update vehiclesToUpdate;
        }
    }
}

public with sharing class InventoryDataScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        externalLegacyConnection();
    }

    @future(callout=true)
    public static void externalLegacyConnection() {
        List<Object> extInventory = getExternalInventory();
        updateInventory(extInventory);
    }

    public static List<Object> getExternalInventory() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://64bjp0q5wg.execute-api.us-east-2.amazonaws.com/Implement/');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        List<Object> result = null;

        if(response.getStatusCode() == 200) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> inventory = (Map<String, Object>) body.get('body');
            result = (List<Object>) inventory.get('Inventory');
        } else {
            System.debug('Error when contacting InventoryData (status code): ' + response.getStatusCode());
        }

        return result;
    }

    private static void updateInventory(List<Object> externalInventories) {
        
        //Create a map to acces external inventory items by ExternalId
        Map<String, Map<String, Object>> extInvMap = new Map<String, Map<String, Object>>();
        for (Object product : externalInventories) {

            extInvMap.put((String) ((Map<String, Object>) product).get('ProductID'),
                (Map<String, Object>) product);
        }

        //Lookup all products with ExternalId that match imported inventories
        List<Product2> products = [
            SELECT Id, Name, ExternalId
            FROM Product2
            WHERE Product2.ExternalId IN :extInvMap.keySet()
        ];

        //Create map of all products by ExternalId
        Map<String, Product2> productsMap = new Map<String, Product2>();
        for (Product2 product : products) {
            productsMap.put(product.ExternalId, product);
        }

        //Create imported products not currently in Salesforce
        List<Product2> newProducts = new List<Product2>();
        if (externalInventories.size() > products.size()) {

            for (String key : extInvMap.keySet()) {
                //If the external product is not in Salesforce, add it
                if (!productsMap.containsKey(key)) {
                    Product2 newProduct = new Product2(Name=key, ExternalId=key);
                    newProducts.add(newProduct);
                }
            }

            insert newProducts;
        }

        //Get current inventories in Salesforce
        List<Inventory__c> inventories = [
            SELECT Id, Name, Available_Quantity__c, Reserved_Quantity__c, Product_Code__c, Product__r.ExternalId
            FROM Inventory__c
            WHERE Product__r.ExternalId IN :extInvMap.keySet()
        ];

        //Create current inventories Map
        Map<String, Inventory__c> invMap = new Map<String, Inventory__c>();
        for (Inventory__c inventory : inventories) {
            invMap.put(inventory.Product__r.ExternalId, inventory);
        }

        //Lookup all products with ExternalId that match imported inventories again
        products = [
            SELECT Id, Name, ExternalId
            FROM Product2
            WHERE Product2.ExternalId IN :extInvMap.keySet()
        ];

        //Create map of all products by ExternalId again
        productsMap = new Map<String, Product2>();
        for (Product2 product : products) {
            productsMap.put(product.ExternalId, product);
        }

        //Upsert recieved inventories
        List<Inventory__c> invToUpsert = new List<Inventory__c>();
        for (String key : extInvMap.keySet()) {
            
            Inventory__c tempInv;

            //Update values if inventory exists
            if (invMap.containsKey(key)) {
                tempInv = invMap.get(key);
                tempInv.Name = (String) extInvMap.get(key).get('name');
                tempInv.Available_Quantity__c = (Integer) extInvMap.get(key).get('Quan');
                tempInv.Reserved_Quantity__c = (Integer) extInvMap.get(key).get('BlockedQuan');
            //Create new Inventory__c item if it doesn't
            } else {
                tempInv = new Inventory__c();
                tempInv.Name = (String) extInvMap.get(key).get('name');
                tempInv.Available_Quantity__c = (Integer) extInvMap.get(key).get('Quan');
                tempInv.Reserved_Quantity__c = (Integer) extInvMap.get(key).get('BlockedQuan');
                tempInv.Product_Code__c = (String) extInvMap.get(key).get('ProductID');
                tempInv.Product__c = productsMap.get(key).Id;
            }
            
            invToUpsert.add(tempInv);
        }

        upsert invToUpsert;
    }
}

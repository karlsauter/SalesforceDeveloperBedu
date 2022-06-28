public with sharing class QuotationHelper implements QuotationSync {
    
    //Returns true if a Product exists and false otherwise
    public Boolean confirmProductExistByCode(String code) {
        
        Product2[] product = [
            SELECT Id
            FROM Product2
            WHERE ExternalId = :code
        ];

        return !product.isEmpty();
    }

    //Returns a Product's Available Quantity (available - reserved)
    public Integer searchProductByCode(String code) {
        
        Integer availableQuantity = 0;
        
        if(confirmProductExistByCode(code)) {
            Inventory__c inventory = [
                SELECT Id,Available_Quantity__c,Reserved_Quantity__c
                FROM Inventory__c
                WHERE Product__r.ExternalId = :code
                LIMIT 1
            ];
            availableQuantity = (Integer)(inventory.Available_Quantity__c - inventory.Reserved_Quantity__c);
        }

        return availableQuantity;
    }

    //Adds quantity to the Reserved_Quantity__c field quantity of Product is available
    public void reserveProductQuantity(List<QuoteLineItem> items, Boolean isBefore, Boolean isAfter) {
        
        Set<Id> productIds = new Set<Id>();
    
        for (QuoteLineItem item : items) {
            productIds.add(item.Product2Id);
        }

        Map<Id, Product2> productsMap = new Map<Id, Product2>([
            SELECT Id, ExternalId, (
                SELECT Id, Reserved_Quantity__c FROM Inventories__r
            )
            FROM Product2
            WHERE Id IN :productIds
        ]);

        if (isBefore) {
            for (QuoteLineItem item : items) {
                if (item.Quantity > searchProductByCode(productsMap.get(item.Product2Id).ExternalId)) {
                    item.addError('Quantity cannot be greater than the Product\'s Available Quantity');
                }
            }
        } else if (isAfter) {
            
            List<Inventory__c> inventoriesToUpdate = new List<Inventory__c>();
            
            for (QuoteLineItem item : items) {
                
                Inventory__c inventoryToUpdate = productsMap.get(item.Product2Id).Inventories__r[0];
                inventoryToUpdate.Reserved_Quantity__c += item.Quantity;
                inventoriesToUpdate.add(inventoryToUpdate);
            }

            update inventoriesToUpdate;
        }
    }

    @invocableMethod(label = 'Stock Empty Alert')
    public static void stockEmptyAlert() {
        
        List<Inventory__c> inventories = productsInInventory();
        List<Inventory__c> inventoriesToUpdate = new List<Inventory__c>();
        FeedItem post = new FeedItem();
        
        post.parentId = UserInfo.getUserId();
        post.isRichText = true;
        post.body = 'El(los) producto(s): ';
        
        //Check Out of Stock inventories and add them to the message body
        for (Inventory__c inventory : inventories) {
            
            Decimal quantity = inventory.Available_Quantity__c - inventory.Reserved_Quantity__c;
            Boolean isTime = inventory.Last_Stock_Alert__c < Datetime.now().addHours(-5) || inventory.Last_Stock_Alert__c == null;

            if(quantity == 0 && isTime) {
                post.body += '<a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + inventory.Id + '">' + inventory.Product__r.Name.escapeHtml4() + '</a>, ';
                inventoriesToUpdate.add(inventory);
            }
        }

        post.body = post.body.substring(0, post.body.length() - 2);
        post.body += ' no tiene(n) existencia en inventario.';

        //Post Chatter message if products where added
        if(post.body.length() > 59) {
            insert post;
        }

        //Update Last_Stock_Alert__c
        for(Inventory__c inventory : inventoriesToUpdate) {
            inventory.Last_Stock_Alert__c = Datetime.now();
        }

        if (!inventoriesToUpdate.isEmpty()) {
            update inventoriesToUpdate;
        }
    }

    public void initialConfig() {
        
        Account[] accList = new List<Account>();
        accList.add(new Account(Name='Compumundo'));
        accList.add(new Account(Name='Compuworld'));

        try {
            insert accList;
        } catch (DmlException e) {
            System.debug('A DML exception has occurred: ' + e.getMessage());
        }
    }

    public static List<Inventory__c> productsInInventory() {
        
        Inventory__c[] inventories = [
            SELECT Name, Product__r.Name, Product_Code__c, Available_Quantity__c, Reserved_Quantity__c, Last_Stock_Alert__c
            FROM Inventory__c
            LIMIT 200
        ];

        return inventories;
    }
}
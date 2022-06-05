public with sharing class QuotationHelper implements QuotationSync {
    public void initialConfig() {
        Account[] accList = new List<Account>();
        accList.add(new Account(Name='Compumundo'));
        accList.add(new Account(Name='Compuworld'));

        try {
            SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.CREATABLE, accList);
            insert securityDecision.getRecords();
        } catch (DmlException e) {
            System.debug('A DML exception has occurred: ' + e.getMessage());
        }
    }

    public Boolean confirmProductExistByCode(String code) {
        Product2[] product = [
            SELECT Id 
            FROM Product2 
            WHERE ExternalId = :code
            WITH SECURITY_ENFORCED
        ];
        return !product.isEmpty();
    }

    public Integer searchProductByCode(String code) {
        
        Integer availableQuantity = 0;
        if(confirmProductExistByCode(code)) {
            Inventory__c inventory = [
                SELECT Id,Available_Quantity__c,Reserved_Quantity__c
                FROM Inventory__c
                WHERE Product__r.ExternalId = :code
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            availableQuantity = (Integer)(inventory.Available_Quantity__c - inventory.Reserved_Quantity__c);
        }

        return availableQuantity;
    }

    public List<Inventory__c> productsInInventory() {
        Inventory__c[] inventory = [
            SELECT Name, Product_Code__c, Available_Quantity__c, Reserved_Quantity__c
            FROM Inventory__c
            WITH SECURITY_ENFORCED
            LIMIT 200];

        return inventory;
    }
}
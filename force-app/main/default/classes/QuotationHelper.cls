public with sharing class QuotationHelper implements QuotationSync {
    public QuotationHelper() {

    }

    public Boolean confirmProductExistByCode(String code) {
        Product2[] product = [
            SELECT Id 
            FROM Product2 
            WHERE ExternalId = :code];
        return !product.isEmpty();
    }

    public Integer searchProductByCode(String code) {
        Inventory__c[] inventory = [
            SELECT Id,Available_Quantity__c,Reserved_Quantity__c 
            FROM Inventory__c
            WHERE Product_Code__c = :code];

        return inventory.isEmpty() ? 
            0 : 
            (Integer)(inventory[0].Available_Quantity__c - inventory[0].Reserved_Quantity__c);
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

    public List<Inventory__c> productsInInventory() {
        Inventory__c[] inventory = [SELECT Name, Product_Code__c, Available_Quantity__c, Reserved_Quantity__c FROM Inventory__c];

        return inventory;
    }
}

public with sharing class QuotationHelper {
    public QuotationHelper() {

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

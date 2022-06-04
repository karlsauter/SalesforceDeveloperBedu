public with sharing class QuotationHelper implements QuotationSync {
    public QuotationHelper() {

    }

    public Boolean confirmProductExistByCode(String code) {
        return this.getProductsByCode(code).isEmpty();
    }

    public Integer searchProductByCode(String code) {
        return this.getProductsByCode(code).size();
    }

    private Products[] getProductsByCode(String code) {
        return [SELECT Id FROM Product2 WHERE ExternalId = :code];
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

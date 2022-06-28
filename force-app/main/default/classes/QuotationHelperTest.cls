@isTest
public with sharing class QuotationHelperTest {

    static Integer numProducts = 10;

    @TestSetup
    static void setup(){
        List<Product2> products = TestDataCreator.createProducts(numProducts);
        TestDataCreator.createInventories(products);
        Pricebook2 pricebook = TestDataCreator.createPricebook();
        TestDataCreator.createPriceBookEntries(products, pricebook);
    }

    @isTest
    public static void testInitialConfig() {
        QuotationHelper qt = new QuotationHelper();
        qt.initialConfig();
        List<Account> accounts = [SELECT Id FROM Account 
            WHERE Name='Compumundo' OR Name='Compuworld'];
        System.assert(accounts.size() == 2, 'No se crearon las cuentas');
    }

    @isTest
    public static void testProductsInInventory() {
        List<Inventory__c> inventories = QuotationHelper.productsInInventory();
        System.assertEquals(numProducts, inventories.size());
    }

    @isTest
    public static void testReserveProductQuantity() {
        QuoteLineItem item = new QuoteLineItem();
        item.Quantity = 3;
        item.Product2Id = [SELECT Id FROM Product2 WHERE Name='Test 1' LIMIT 1].Id;
        List<QuoteLineItem> items = new List<QuoteLineItem>();
        items.add(item);

        QuotationHelper qt = new QuotationHelper();
        qt.reserveProductQuantity(items, true, false);
        qt.reserveProductQuantity(items, false, true);

        Inventory__c inventory = [SELECT Reserved_Quantity__c FROM Inventory__c WHERE Product__c = :item.Product2Id LIMIT 1];
        System.assertEquals(3, inventory.Reserved_Quantity__c);
    }
}

@isTest
public with sharing class InventoryDataSchedulerTest {

    @testSetup
    static void setup() {
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name='CL1010', ExternalId='CL1010'));
        products.add(new Product2(Name='MC1020', ExternalId='MC1020'));

        insert products;
        
        Inventory__c inv = new Inventory__c();
        inv.Name = 'CL1010_Inv';
        inv.Product_Code__c = 'CL1010';
        inv.Available_Quantity__c = 2800;
        inv.Reserved_Quantity__c = 25;
        inv.Product__c = products[0].Id;

        insert inv;  
    }

    @isTest
    public static void testInventoryDataScheduler() {
        //Set Http mock class
        Test.setMock(HttpCalloutMock.class, new ExternalInventoryMock());
        //Set cron schedule string
        String cronExp = '0 0 0 1 1 ?';

        //Run tests
        Test.startTest();
        //Schedule task
        String jobId = System.schedule('Inventory Data Scheduler Test',
            cronExp,
            new InventoryDataScheduler());
        Test.stopTest();

        //Verify task ran was scheduled correctly
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assert(jobs.size() > 0);
    }

    @isTest
    public static void testGetExternalInventory() {
        Test.setMock(HttpCalloutMock.class, new ExternalInventoryMock());
        Test.startTest();
        List<Object> result = InventoryDataScheduler.getExternalInventory();
        Test.stopTest();
        System.assertEquals(3, result.size());
    }

    @isTest
    public static void testExternalLegacyConnection() {
        Test.setMock(HttpCalloutMock.class, new ExternalInventoryMock());
        Test.startTest();
        InventoryDataScheduler.externalLegacyConnection();
        Test.stopTest();

        List<Product2> products = [SELECT Id FROM Product2];
        List<Inventory__c> invs = [SELECT Id FROM Inventory__c];
        Inventory__c inv = [
            SELECT Id, Available_Quantity__c, Reserved_Quantity__c 
            FROM Inventory__c
            WHERE Product_Code__c = 'CL1010'
        ];
        System.assertEquals(3, products.size(), 'Products not created');
        System.assertEquals(3, invs.size(), 'Inventories not created');
        System.assertEquals(2906, inv.Available_Quantity__c, 'Available Quantity not updated');
        System.assertEquals(8, inv.Reserved_Quantity__c, 'Reserved Quantity not updated');
    }
}

public with sharing class CustomWebInventoryController {
    
    private final Quote parent;
    public String code { get; set; }
    public List<Product2> products { get; set; }
    public String name { get; set; }
    public String externalId { get; set; }
    public Decimal price { get; set; }
    public Integer available { get; set; }
    public Integer quantity { get; set; }
    public Boolean detailsVisible { get; set; }
    public static String priceBookId { get; set; }
    public String priceBookEntryId { get; set; }
    
    public CustomWebInventoryController(ApexPages.StandardController controller) {
        this.parent = (Quote) controller.getRecord();
        this.detailsVisible = false;
        this.quantity = 0;
    }

    public void search() {
        if(code != null && code != '') {
            this.products = searchProducts(code, parent.Id);
        }
        if (products != null && products.size() > 0) {
            this.name = products[0].Name;
            this.externalId = products[0].ExternalId;
            this.price = products[0].PricebookEntries[0].UnitPrice;
            this.priceBookEntryId = products[0].PricebookEntries[0].Id;
            this.available = (Integer)
                (products[0].Inventories__r[0].Available_Quantity__c - 
                products[0].Inventories__r[0].Reserved_Quantity__c);
            this.detailsVisible = true;
        } else {
            String error = 'No products with that code';
            ApexPages.Message message = new ApexPages.Message(ApexPages.severity.ERROR, error);
            ApexPages.addMessage(message);    
        }
    }

    public void clear() {
        this.products.clear();
        this.detailsVisible = false;
    }

    public void save() {
        if (quantity > 0 && quantity <= available) {
            QuoteLineItem newLine = new QuoteLineItem();
            newLine.Product2Id = products[0].Id;
            newLine.Quantity = quantity;
            newLine.UnitPrice = price;
            newLine.QuoteId = parent.Id;    
            newLine.PricebookEntryId = priceBookEntryId;
            try {
                insert newLine;
            } catch (DmlException e) {
                String error = 'There was a problem creating the record';
                ApexPages.Message message = new ApexPages.Message(ApexPages.severity.ERROR, error);
                ApexPages.addMessage(message);
            }
            String confirm = 'Record was inserted';
            ApexPages.Message message = new ApexPages.Message(ApexPages.severity.CONFIRM, confirm);
            ApexPages.addMessage(message);
            this.clear();
        } else {
            String error = 'Quantity must more than 0 and less than Available';
            ApexPages.Message message = new ApexPages.Message(ApexPages.severity.ERROR, error);
            ApexPages.addMessage(message);
        }
    }

    @AuraEnabled
    public static List<Product2> searchProducts(String productCode, Id quoteId) {
        try {
            List<Quote> quote = [SELECT Pricebook2Id FROM Quote WHERE Id = :quoteId];
        
            priceBookId = quote[0].Pricebook2Id;
    
            return [
                SELECT Id, Name, ExternalId, (
                    SELECT Id, UnitPrice 
                    FROM PricebookEntries
                    WHERE Pricebook2Id = :priceBookId), (
                    SELECT Available_Quantity__c, Reserved_Quantity__c
                    FROM Inventories__r
                    )
                FROM Product2
                WHERE ExternalId = :productCode
            ];    
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}

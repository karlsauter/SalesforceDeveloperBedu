trigger AddQuotationLineItem on QuoteLineItem (before insert, after insert) {
    
    QuotationHelper qh = new QuotationHelper();
    qh.reserveProductQuantity(Trigger.new, Trigger.isBefore, Trigger.isAfter);

}
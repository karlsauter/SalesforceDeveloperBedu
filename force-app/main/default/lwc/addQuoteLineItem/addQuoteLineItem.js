import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { createRecord } from 'lightning/uiRecordApi';
import searchProducts from '@salesforce/apex/CustomWebInventoryController.searchProducts';

import LOCALE from '@salesforce/i18n/locale';
import CURRENCY from '@salesforce/i18n/currency';

import QLI_OBJECT from '@salesforce/schema/QuoteLineItem';
import PRODUCTID_FIELD from '@salesforce/schema/QuoteLineItem.Product2Id';
import QUOTEID_FIELD from '@salesforce/schema/QuoteLineItem.QuoteId';
import PBEID_FIELD from '@salesforce/schema/QuoteLineItem.PricebookEntryId';
import QUANTITY_FIELD from '@salesforce/schema/QuoteLineItem.Quantity';
import UNITPRICE_FIELD from '@salesforce/schema/QuoteLineItem.UnitPrice';

export default class AddQuoteLineItem extends LightningElement {
    
    @api recordId;
    notFound;
    error;

    @track fields = {
        productCode: '',
        quantity: ''
    }

    pricebookEntryId;
    invetoryId;
    unitPrice;

    _product;
    set product(items) {
        if(Array.isArray(items)) {
            const item = items[0];
            const newProduct = {
                Id: item.Id,
                Name: item.Name,
                Price: new Intl.NumberFormat(LOCALE, {
                    style: 'currency',
                    currency: CURRENCY,
                    currencyDisplay: 'symbol'
                }).format(item.PricebookEntries[0].UnitPrice),
                Available: item.Inventories__r[0].Available_Quantity__c - item.Inventories__r[0].Reserved_Quantity__c,
                ExternalId: item.ExternalId,
            }
            this._product = newProduct;
        } else {
            this._product = items;
        }
    }
    get product() {
        return this._product;
    }



    handleChange(e) {
        const name = e.target.name;
        const value = e.target.value;
        this.fields[name] = value;
    }

    handleKeyUp(e) {
        const isEnterKey = e.keyCode === 13;
        if (isEnterKey) {
            this.handleSearch();
        }
    }

    handleSearch() {
        if (this.fields.productCode !== '') {
            searchProducts({ productCode: this.fields.productCode, quoteId: this.recordId  })
            .then((result) => {
                if (result && result.length > 0) {
                    this.clearFields();
                    this.product = result;
                    this.pricebookEntryId = result[0].PricebookEntries[0].Id;
                    this.invetoryId = result[0].Inventories__r[0].Id;
                    this.unitPrice = result[0].PricebookEntries[0].UnitPrice;
                } else {
                    this.clearFields();
                    this.notFound = 'No products found';
                }
            })
            .catch((error) => {
                this.clearFields();
                this.error = error;
            })
        } else {
            this.clearFields();
            this.notFound = 'Please enter a Product Code';
        }
    }

    handleReset() {
        this.clearFields();
        this.fields.productCode = '';
    }

    clearFields() {
        this.product = undefined;
        this.error = undefined;
        this.notFound = undefined;
        this.fields.quantity = '';
    }

    handleAddProduct() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        if (isInputsCorrect) {
            const fields = {};
            fields[PRODUCTID_FIELD.fieldApiName] = this.product.Id;
            fields[QUOTEID_FIELD.fieldApiName] = this.recordId;
            fields[PBEID_FIELD.fieldApiName] = this.pricebookEntryId;
            fields[QUANTITY_FIELD.fieldApiName] = parseInt(this.fields.quantity);
            fields[UNITPRICE_FIELD.fieldApiName] = this.unitPrice;
            const recordInput = { apiName: QLI_OBJECT.objectApiName, fields };

            createRecord(recordInput)
                .then(response => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Product added to Quote',
                            variant: 'success',
                        }),
                    );
                    eval("$A.get('e.force:refreshView').fire();");
                    this.clearFields();
                    this.fields.productCode = '';
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                })

        }
    }
}
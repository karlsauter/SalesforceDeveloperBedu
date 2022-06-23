import { LightningElement, api, wire, track } from 'lwc';

import searchProducts from '@salesforce/apex/CustomWebInventoryController.searchProducts';

export default class AddQuoteLineItem extends LightningElement {
    
    @api recordId;
    productCode = '';
    _products;
    set products(items) {
        if(Array.isArray(items)) {
            this._products = [];
            for(const item of items) {
                const newProduct = {
                    Name: item.Name,
                    Price: item.PricebookEntries[0].UnitPrice,
                    Available: item.Inventories__r[0].Available_Quantity__c - item.Inventories__r[0].Reserved_Quantity__c,
                    ExternalId: item.ExternalId,
                }
                this._products.push(newProduct);
            }    
        }
    }
    get products() {
        return this._products;
    }
    notFound;
    error;

    handleChange(e) {
        this.productCode = e.target.value;
    }

    handleKeyUp(e) {
        const isEnterKey = e.keyCode === 13;
        if (isEnterKey) {
            this.handleSearch();
        }
    }

    handleSearch() {
        if (this.productCode !== '') {
            searchProducts({ productCode: this.productCode, quoteId: this.recordId  })
            .then((result) => {
                if (result && result.length > 0) {
                    this.products = result;
                    this.error = undefined;
                    this.notFound = undefined;        
                } else {
                    this.notFound = 'No products found';
                    this.products = undefined;
                    this.error = undefined;
                }
            })
            .catch((error) => {
                this.error = error;
                this.products = undefined;
                this.notFound = undefined;
            })
        } else {
            this.notFound = 'A product code is required';
        }
    }

    handleReset() {
        this.productCode = '';
        this.products = undefined;
        this.error = undefined;
        this.notFound = undefined;
    }
}
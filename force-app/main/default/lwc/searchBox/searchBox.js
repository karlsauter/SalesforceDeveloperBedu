import { LightningElement, api } from 'lwc';

export default class SearchBox extends LightningElement {

    @api productCode = '';

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
        let event = new CustomEvent('search', {
            detail: this.productCode
        });
        this.dispatchEvent(event);
    }
}
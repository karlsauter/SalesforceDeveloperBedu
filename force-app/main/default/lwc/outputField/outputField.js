import { LightningElement, api } from 'lwc';

export default class OutputField extends LightningElement {
    @api label;
    @api value;
}
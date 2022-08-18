import { LightningElement, wire, api, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import COMMENTS_FIELD from '@salesforce/schema/Case.PC_Specialist_Comments__c';
import cancelCase from '@salesforce/apex/PC_ProviderConnectController.cancelCase';


export default class PcCancelCase extends LightningElement {
    @api recordId
    @track showConfirm = false;
    @track showSpinner = false;

    @wire(getRecord, { recordId: '$recordId', fields: [COMMENTS_FIELD] })
    pcCaseRaw

    cancelReason

    get pcCase() {
        return this.pcCaseRaw && this.pcCaseRaw.data ? this.pcCaseRaw.data : {}
    }

    get disableSave() {
        return !this.cancelReason
    }

    handleChange(event) {
        this.cancelReason = event.target.value
    }

    handleCancelClicked(){
        this.showConfirm = true;
    }

    handleCloseConfirm() {
        this.showConfirm = false;
    }


    saveReason() {
        this.showSpinner = true;
        this.handleCloseConfirm();

        cancelCase({caseId: this.recordId})
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Case cancelled.',
                        variant: 'success'
                    })
                );
                getRecordNotifyChange([{recordId: this.recordId}]);

            })
            .catch(error => {
                let variant = ''
                let title = ''
                if(error.body && error.body.message.includes('This case is already closed.')){
                    variant = 'warning'
                    title = 'Case Closed'
                } else {
                    variant = 'error'
                    title = 'Error Cancelling Case'
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: title,
                        message: error.body ? error.body.message : error.message,
                        variant: variant
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
            })
        }
}
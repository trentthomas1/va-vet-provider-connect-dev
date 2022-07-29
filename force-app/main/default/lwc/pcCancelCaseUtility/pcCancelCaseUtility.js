import { LightningElement, track } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import cancelOpenCases from '@salesforce/apex/PC_ProviderConnectController.cancelOpenCases';

export default class PcCancelCaseUtility extends LightningElement {
    @track showConfirm = false;
    @track showSpinner = false;

    cancelReason = ''

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

        cancelOpenCases({cancelReason: this.cancelReason})
            .then(results => {
                if(results.length === 0){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'No Open Cases',
                            message: 'You do not have any open cases.',
                            variant: 'error'
                        })
                    );
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Cases closed.',
                            variant: 'success'
                        })
                    );

                    this.cancelReason = ''

                    results.forEach(id => {
                        getRecordNotifyChange([{recordId: id}]);
                    })
                }
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Closing Case',
                        message: error.body ? error.body.message : error.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
            })
        
        this.showConfirm = false;
    }
}
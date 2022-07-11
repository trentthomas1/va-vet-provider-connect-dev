import { LightningElement, track } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PcFeedback extends LightningElement {
    feedback = ''
    @track showSpinner = false

    get isDisabled() {
        return !this.feedback
    }

    handleChange(event) {
        this.feedback = event.target.value
    }

    saveFeedback(){
        this.showSpinner = true
        var fields = {'Feedback__c' : this.feedback};
        var objRecordInput = {'apiName' : 'PC_Feedback__c', fields};
        createRecord(objRecordInput).then(response => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Feedback saved successfully.',
                    variant: 'success'
                })
            );
            this.feedback = ''
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong retrieving the survey, please contact your system administrator:\n' +JSON.stringify(error, 0, 2),
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.showSpinner = false
        });
    }
}
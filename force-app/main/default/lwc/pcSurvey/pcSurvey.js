import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {refreshApex} from '@salesforce/apex';
import getSurvey from '@salesforce/apex/PC_SurveyController.getSurvey';
import saveSurvey from '@salesforce/apex/PC_SurveyController.saveSurvey';

export default class PcSurvey extends LightningElement {

    @api recordId
    @track showSpinner = true;

    @wire(getSurvey, {caseId: '$recordId'})
    getSurveyFunc(result) {
        this.result = result
        if (result.data) {
            this.survey = {...result.data};
            this.showSpinner = false;
            let stars = this.template.querySelectorAll('input');

            stars.forEach( star => {
                star.checked = false;
                if(star.value <= this.survey.PC_Was_this_session_useful__c){
                    star.checked = true;
                }
            })
            this.showSpinner = false
        } else if (result.error) {
            this.showSpinner = false;
            console.error(result.error)
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong retrieving the survey, please contact your system administrator.',
                    variant: 'error'
                })
            );
        }
        
    }
    
    handleChange(event) {
        this.showSpinner = true;
        this.survey.PC_Was_this_session_useful__c = event.target.value
        saveSurvey( {survey: this.survey} )
        .then( result => {
            this.handleRefresh()
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Survey saved successfully.',
                    variant: 'success'
                })
            );
        })
        .catch( error => {
            this.showSpinner = false;
            console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong saving the survey, please contact your system administrator.',
                    variant: 'error'
                })
            );
        }) 
    }

    handleRefresh() {
        refreshApex(this.result)
    }

}

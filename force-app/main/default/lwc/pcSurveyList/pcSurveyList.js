import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSurveysToComplete from '@salesforce/apex/PC_SurveyController.getSurveysToComplete';

export default class PcSurveyList extends LightningElement {
    @track showSurvey = false;
    @track showSpinner = true;

    data = []

    columns = [
        {
            label: 'Case',
            fieldName: 'caseUrl',
            type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'CaseNumber'
                },
                target: '_self'
            }
        },
        {
            type: 'date',
            label: 'Consult Date',
            fieldName: 'CreatedDate',
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            }
        },
        { label: 'Specialty', fieldName: 'PC_Specialty__c' },
        { label: 'Channel', fieldName: 'PC_Channel__c' },
        { label: 'Consultant', fieldName: 'agent' },
        {
            type: 'button',
            label: 'Survey',
            typeAttributes: {
                label: 'Take Survey',
                name: 'Take Survey',
                title: 'Take Survey',
                disabled: false,
                value: 'survey',
                iconPosition: 'left'
            }
        },
        // {
        //     type: 'action',
        //     typeAttributes: { rowActions: [{ label: 'Take Survey', name: 'survey' }] },
        // },

    ];

    @wire(getSurveysToComplete)
    getCases(result) {
        this.result = result
        if (result.data) {
            let tempData = [...result.data];
            if(tempData.length > 0) {
                this.showEmpty = false;
            } else{
                this.showEmpty = true
            }
            this.data = [];
            tempData.forEach(tempRecord => {
                let record = {...tempRecord}
                record.caseUrl = '/lightning/r/' + tempRecord.Id + '/view'
                record.agent = record.Owner.Name
                this.data.push(record)
            })
        } else if (result.error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong retrieving cases, please contact your system administrator.\n' + JSON.stringify(result.error) ,
                    variant: 'error'
                })
            );
        }
        this.showSpinner = false;

    }

    handleRowAction(event) {

        // const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.currentId = row.Id;
        this.currentCaseName = row.CaseNumber;
        this.showSurvey = true
    }

    closeSurvey() {
        this.showSpinner = true
        this.showSurvey = false;
        this.handleRefresh()
    }

    handleRefresh() {
        refreshApex(this.result)
        this.showSpinner = false;
    }

}
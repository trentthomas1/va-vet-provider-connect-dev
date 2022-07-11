import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {refreshApex} from '@salesforce/apex';
import getChannelAvailability from '@salesforce/apex/PC_ProviderConnectController.getChannelAvailability';
import setChannelAvailability from '@salesforce/apex/PC_ProviderConnectController.setChannelAvailability';

export default class PcChannelSelection extends LightningElement {

    @track channels = {}
    @track showSpinner = true

    @wire(getChannelAvailability)
    channelAvailability(result) {
        this.result = result
        console.log(result)
        if (result.data) {
            this.channels = result.data;
            this.chatVariant = this.channels.chat ? 'brand' : 'neutral'
            this.phoneVariant = this.channels.phone ? 'brand' : 'neutral'
            this.teamsVariant = this.channels.teams ? 'brand' : 'neutral'
            this.showSpinner = false;
        } else if (result.error) {
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Loading Page',
                    message: 'Something went wrong getting your availability, please contact your system administrator.',
                    variant: 'error'
                })
            );
        }
    }
    
    handleButtonSelection(event){
        //Toggle boolean was causing issues
        this.showSpinner = true;
        let value
        if(event.target.dataset.value === true || event.target.dataset.value === 'true'){
            value = false
        } else{
            value = true
        }
        setChannelAvailability({channel: event.target.name, value: value})
        .then(result => {
            this.handleRefresh()
            if(result !== 'success') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result,
                        variant: 'error'
                    })
                );
                this.showSpinner = false
            }
        })
        .catch(error => {
            console.log(error)
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Loading Page',
                    message: 'Something went wrong setting your availability, please contact your system administrator.',
                    variant: 'error'
                })
            );
        })
    }

    handleRefresh() {
        refreshApex(this.result)
    }
}
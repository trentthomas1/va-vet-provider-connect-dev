import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getChatterMessages from '@salesforce/apex/PC_ChatController.getChatterMessages';
import getChatterMessagesCache from '@salesforce/apex/PC_ChatController.getChatterMessagesCache';
import saveChatterMessage from '@salesforce/apex/PC_ChatController.saveChatterMessage';
import closeChatSession from '@salesforce/apex/PC_ChatController.closeChatSession';

import Id from '@salesforce/user/Id';

import isSpecialist from '@salesforce/customPermission/PC_Specialist';


export default class PcChat extends LightningElement {
    @api sessionId
    @api recordId
    @api refreshSeconds = 1
    @track showSpinner


    @track messages = [];
    @track session = {}
    transcript = ''
    mostRecentMessage = ''
    @track newMessage = ''

    @track isClosed
    closedBy
    closedDate

    userId = Id;

    errorCounter = 0;

    get disableSend() {
        return !this.newMessage
    }

    get showCopy() {
        return isSpecialist && this.isClosed
    }

    get charLength () {
        return this.newMessage.length;
    }

    connectedCallback() {
        this.showSpinner = true;
        this.getChatter();
		this.getMessageInterval = setInterval(this.getChatterCache.bind(this), this.refreshSeconds * 1000);
        this.showSpinner = false;

	}

    disconnectedCallback() {
        clearInterval(this.getMessageInterval)
    }

    getChatter() {
        getChatterMessages({sessionId: this.sessionId, caseId: this.recordId, lastMessageTime: this.mostRecentMessage})
        .then( result => {
            if(result.Id) {
                this.session = {...result}
                this.sessionId = this.session.Id
                
                this.startedBy = this.session.CreatedBy.Name

                if(this.session.Feeds) {
                    this.messages =  this.messages.concat(this.session.Feeds)
                    this.mostRecentMessage = this.messages[this.messages.length - 1].CreatedDate;
                    this.messages.forEach( message => {
                        if(Id === message.InsertedById) {
                            message.listClasses = 'slds-chat-listitem slds-chat-listitem_outbound'
                            message.messageClasses = 'slds-chat-message__text slds-chat-message__text_outbound'
                        } else {
                            message.listClasses = 'slds-chat-listitem slds-chat-listitem_inbound'
                            message.messageClasses = 'slds-chat-message__text slds-chat-message__text_inbound'
                        }
                    })
                    setTimeout(() => {
                        let lastIndex = this.messages.length - 1
                        this.scrollToMessage(this.messages[lastIndex].Id)
                    }, 500)
                }
                
                if(this.session.PC_Is_Closed__c) {
                    this.isClosed = true;
                    this.closedBy = this.session.PC_Closed_By__r.Name;
                    this.closedDate = this.session.PC_Closed_Date__c
                    clearInterval(this.getMessageInterval)
            
                    this.transcript += 'Chat started by ' + this.startedBy + ' • ' + this.formatToLocale(this.session.CreatedDate) + '\n\n\n'
                    this.messages.forEach( message => {
                        this.transcript += message.InsertedBy.Name + ' • ' + this.formatToLocale(message.CreatedDate) + '\n' + message.Body + '\n\n'
                    })
                    this.transcript += '\nChat ended by ' + this.closedBy + ' • ' + this.formatToLocale(this.closedDate)
                }
            }
        })
        .catch( error => {
            
            if(this.errorCounter%10 === 0) {
                console.error(error)
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: error.body ? error.body.message : error.message,
                        title: 'Error occurred trying to retrieve chat',
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
                // clearInterval(this.getMessageInterval)
                this.retry = true
            }
            this.errorCounter++
        })
    }

    getChatterCache() {
        if(this.sessionId) {
        getChatterMessagesCache({sessionId: this.sessionId, lastMessageTime: this.mostRecentMessage})
        .then( result => {
            this.retry = false
            this.isClosed = result.isClosed
            this.closedBy = result.closedBy
            this.closedDate = result.closedDate
            let chatList = [...result.chatList];
            if(chatList.length) {
                this.messages =  this.messages.concat(chatList)
                this.mostRecentMessage = this.messages[this.messages.length - 1].CreatedDate;
                this.messages.forEach( message => {
                    if(Id === message.InsertedById) {
                        message.listClasses = 'slds-chat-listitem slds-chat-listitem_outbound'
                        message.messageClasses = 'slds-chat-message__text slds-chat-message__text_outbound'
                    } else {
                        message.listClasses = 'slds-chat-listitem slds-chat-listitem_inbound'
                        message.messageClasses = 'slds-chat-message__text slds-chat-message__text_inbound'
                    }
                })
                setTimeout(() => {
                    let lastIndex = this.messages.length - 1
                    this.scrollToMessage(this.messages[lastIndex].Id)
                }, 500)
            }
            
            if(this.isClosed) {
                clearInterval(this.getMessageInterval)

                this.transcript += 'Chat started by ' + this.startedBy + ' • ' + this.formatToLocale(this.session.CreatedDate) + '\n\n\n'
                this.messages.forEach( message => {
                    this.transcript += message.InsertedBy.Name + ' • ' + this.formatToLocale(message.CreatedDate) + '\n' + message.Body + '\n\n'
                })
                this.transcript += '\nChat ended by ' + this.closedBy + ' • ' + this.formatToLocale(this.closedDate)
            }
        })
        .catch( error => {
            console.error(error)
            //If there is error with cache, fetch chat list from database
            this.getChatter()
        })
    }
    }

    handleCopy() {
        try {
            navigator.clipboard.writeText(this.transcript);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: '',
                    message: 'Copied',
                    variant: 'success'
                })
            );
        } catch {
            let tempTextAreaField = document.createElement('textarea');
            tempTextAreaField.style = 'position:fixed;top:-5rem;height:1px;width:10px;';
            tempTextAreaField.value = this.transcript;
            document.body.appendChild(tempTextAreaField);
            tempTextAreaField.select();
            document.execCommand('copy');
            tempTextAreaField.remove();

            this.dispatchEvent(
                new ShowToastEvent({
                    title: '',
                    message: 'Copied',
                    variant: 'success'
                })
            );
        }

    }

    formatToLocale(dt) {
        var date = new Date(dt);
        return date.toString()
    }

    handleChange(event) {
        this.newMessage = event.target.value;
    }

    handleSendMessage(event) {
        if (this.newMessage && (event.key === 'Enter' || event.keyCode === 13 || event.target.dataset.id ==="button")) {
            let tempMessage = this.newMessage
            this.newMessage = ''
            saveChatterMessage({sessionId : this.sessionId, message: tempMessage})
            .catch( error => {
                console.error(error)
                this.newMessage = tempMessage
            })
        }
    }

    handleEndChat() {
        this.showSpinner = true
        closeChatSession({sessionId : this.sessionId})
        .then(result => {
            clearInterval(this.getMessageInterval)
            this.session = {...result}
            this.isClosed = true;
            this.closedBy = this.session.PC_Closed_By__r.Name;
            this.closedDate = this.session.PC_Closed_Date__c
            setTimeout(() => {
                this.getChatterCache()
            }, 1000)

        })
        .finally( () => {
            this.showSpinner = false;
        })
    }

    scrollToMessage(messageId) {
        try{
            this.template.querySelector('[data-id="'+ messageId +'"]').scrollIntoView({behavior: "smooth", block: "center", inline: "nearest"});
        } catch(e) {
            console.error(e)
        }
    }

}
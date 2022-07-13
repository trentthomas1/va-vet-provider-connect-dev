import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAgentHistory from '@salesforce/apex/PC_ManagerController.getAgentHistory';

export default class PcOmniChannelSupervisor extends LightningElement {
    refreshSeconds = 5
    @track agentStatus = []
    @track showSpinner
    currentAgent = ''
    currentView = ''
    selectedAgent = {}

    allCaseColumns = [
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
        { label: 'Channel', fieldName: 'PC_Channel__c' },
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
        {
            type: 'date',
            label: 'Closed Date',
            fieldName: 'ClosedDate',
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            }
        },
        { label: 'Status', fieldName: 'Status'},
        { label: 'Specialty', fieldName: 'PC_Specialty__c' },
    ]

    historyColumns = [
        {
            label: 'Status', fieldName: 'status',
        },
        {
            type: 'date',
            label: 'Start',
            fieldName: 'StatusStartDate',
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            }
        },
        {
            type: 'date',
            label: 'End',
            fieldName: 'StatusEndDate',
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            }
        },
        { label: 'Duration (Hours)', fieldName: 'durationHours'},
        {
            label: 'Average Capacity', 
            fieldName: 'averageCapacityPct', 
            type: 'percent',
            typeAttributes: {
                maximumFractionDigits : 2,
                minimumFractionDigits : 2
            }
        },
        { label: 'Specialty', fieldName: 'PC_Specialty__c'},
        { label: 'Chat', fieldName: 'PC_Chat_Channel__c', type: 'boolean'},
        { label: 'Teams', fieldName: 'PC_Teams_Channel__c', type: 'boolean' },
        { label: 'Phone', fieldName: 'PC_Phone_Channel__c', type: 'boolean' },
    ]

    openCaseColumns = [
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
        { label: 'Channel', fieldName: 'PC_Channel__c' },
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
        
    ]

    connectedCallback() {
		this.buildAgenHistory();
		setInterval(this.buildAgenHistory.bind(this), this.refreshSeconds * 1000);
	}

    buildAgenHistory() {
		getAgentHistory()
        .then( result => {
            let isOpen = this.agentStatus.find(a => a.showHistory  || a.showCases)
            this.agentStatus = [...result]
            this.specialistOptions = [];

            this.agentStatus.forEach((agent) => {
                this.specialistOptions.push({value: agent.agentId, label: agent.agentName})

                agent.caseButton = 'Show Open Cases - ' + agent.openCases.length
                agent.historyButton = 'Show History'
                if(agent.agentId === this.currentAgent && isOpen) {
                    if(this.currentView === 'case'){
                        agent.showCases = true
                        agent.caseButton = 'Hide Cases'
                    }else{
                        agent.showHistory = true
                        agent.historyButton = 'Hide History'
                    }
                }

                switch(agent.currentStatus) {
                    case 'Available':
                        agent.colorStatus = 'available'
                        agent.sortOrder = 1
                        break;
                    case 'Wrap Up':
                        agent.colorStatus = 'wrap-up'
                        agent.sortOrder = 2
                        break;
                    default:
                        agent.colorStatus = 'offline'
                        agent.sortOrder = 3
                }


                agent.openCases.forEach(c => {
                    c.caseUrl = '/'+c.Id
                })

                agent.allCases.forEach(c => {
                    c.caseUrl = '/'+c.Id
                })

                if(agent.historicStatuses.length) {
                    agent.currentPresence = agent.historicStatuses[0]
                    agent.currentPresence.since = agent.currentPresence.StatusEndDate
                    if(agent.historicStatuses[0].IsCurrentState) {
                        agent.currentPresence.since = agent.currentPresence.StatusStartDate
                        agent.historicStatuses.splice(0, 1)
                    }
                }

                agent.historicStatuses.forEach(h => {
                    h.status = h.ServicePresenceStatus.MasterLabel
                    h.averageCapacityPct = h.AverageCapacity / h.ConfiguredCapacity
                    if(h.StatusDuration) {
                        let hours = Math.floor(h.StatusDuration / 60 / 60);
                        let minutes = Math.floor(h.StatusDuration / 60) - (hours * 60);
                        let seconds = h.StatusDuration % 60;
                        h.durationHours = (hours > 9 ? hours : '0' + hours) + ':' + (minutes > 9 ? minutes : '0' + minutes) + ':' + (seconds > 9 ? seconds : '0' + seconds)
                    }
                })
                
            })

            this.agentStatus.sort(( a, b ) => {
                if ( a.sortOrder < b.sortOrder ){
                  return -1;
                }
                if ( a.sortOrder > b.sortOrder ){
                  return 1;
                }
                return 0;
            })
        })
        .catch( error => {
				this.dispatchEvent(
					new ShowToastEvent({
						message: error.body ? error.body.message : error.message,
						title: 'Error occurred trying to retrieve agent history',
						variant: 'error',
						mode: 'sticky'
					})
				);
        })
    }

    handleShowCases(event) {
        this.showSpinner = true
        this.agentStatus.forEach(a => {
            let tempShowCases = a.showCases

            a.showHistory = false;
            a.showCases = false;
            a.caseButton = 'Show Open Cases - ' + a.openCases.length
            a.historyButton = 'Show History'
            if(a.agentId === event.target.dataset.agentid && !tempShowCases) {
                this.currentAgent = a.agentId;
                this.currentView = 'case'
                a.showCases = true;
                a.caseButton = 'Hide Cases'
            }
        })
        this.showSpinner = false
    }

    handleShowHistory(event) {
        this.showSpinner = true
        this.agentStatus.forEach(a => {
            let tempShowHistory = a.showHistory
            a.showHistory = false;
            a.showCases = false;
            a.caseButton = 'Show Open Cases - ' +  a.openCases.length
            a.historyButton = 'Show History'         
            if(a.agentId === event.target.dataset.agentid && !tempShowHistory) {
                this.currentAgent = a.agentId;
                this.currentView = 'history'
                a.showHistory = true;
                a.historyButton = 'Hide History'
            }
        })
        this.showSpinner = false
    }

    handleAgentChange(event) {
        this.selectedAgent = this.agentStatus.find(agent => agent.agentId === event.detail.value)
    }
}
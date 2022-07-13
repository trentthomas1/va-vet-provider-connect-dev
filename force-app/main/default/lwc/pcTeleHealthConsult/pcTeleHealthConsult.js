/* eslint-disable no-unused-vars */
/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

import Id from '@salesforce/user/Id';
import phone from '@salesforce/schema/User.Phone';
import ext from '@salesforce/schema/User.Extension';



import getSkills from '@salesforce/apex/PC_ProviderConnectController.getSkills';
import createCase from '@salesforce/apex/PC_ProviderConnectController.createCase';
import getAssignedAgent from '@salesforce/apex/PC_ProviderConnectController.getAssignedAgent';
import cancelCase from '@salesforce/apex/PC_ProviderConnectController.cancelCase';


export default class TeleHealthConsultation extends NavigationMixin(LightningElement) {
	@api refreshSeconds = 5;
	@api minimumSkillLevel = 0;

	@track skillsAndButtons = [];
	myCases = []
	selectedSkill = null;
	consultChannel = null;
	channelShort = null;
	veteranMemberId;
	caseDetails;
	caseDetailsChars = 0;
	maxDetailsChars = 32000;
	showSpinner = false;
	@track showPhoneModal = false;
	@track showConfirmModal = false;
	@track showCaseModal = false;
	progressLabel = 'Loading...';
	callback;
	error;
	caseObj = {}
	currentClosedCase = {}
	@wire(getRecord, { recordId: Id, fields: [phone, ext] })
	userDetails({ error, data }) {
		if (data) {
			this.callback = data.fields.Phone.value;
			this.callbackExt = data.fields.Extension.value
		} else if (error) {
			this.error = error;
		}
	}

	get disablePhoneConnect() {
		return !this.callback
	}

	get detailsCharsRemaining() {
		return this.maxDetailsChars - this.caseDetailsChars;
	}

	get connectButtonDisable() {
		const presence = this.skillsAndButtons.reduce((pres, skill) => pres || skill.skillHasPresence, false);
		return !presence || (this.selectedSkill === null);
	}

	get isChat() {
		return this.consultChannel === 'Chat'
	}

	get isPhone() {
		return this.consultChannel === 'Phone'
	}

	get isTeams() {
		return this.consultChannel === 'Teams'
	}

	connectedCallback() {
		this.currentTime = new Date();
		this.buildSkillOptions();
		setInterval(this.buildSkillOptions.bind(this), this.refreshSeconds * 1000);
	}

	buildSkillOptions() {
		getSkills({queryDate: this.currentTime})
			.then((result) => {
				this.skillsAndButtons = [];
				result.statuses.forEach((skill) => {
					this.skillsAndButtons.push({
						skillName: skill.skillName,
						skillHasPresence: skill.hasPresence,
						skillNameFormat: !skill.hasPresence || (skill.minCapacity === 20.0) ? 'slds-text-color_inverse-weak' : 'slds-text-color_default',
						minCapacity: skill.minCapacity,
						chat: {
							disabled: skill.chatDisabled,
							variant: skill.skillName === this.selectedSkill && this.channelShort === 'chat' ? 'brand' : 'neutral'
						},
						teams: {
							disabled: skill.teamsDisabled,
							variant: skill.skillName === this.selectedSkill && this.channelShort === 'teams' ? 'brand' : 'neutral'
						},
						phone: {
							disabled: skill.phoneDisabled,
							variant: skill.skillName === this.selectedSkill && this.channelShort === 'phone' ? 'brand' : 'neutral'
						}
					});
				});

				if(result.myCases.length > 0) {
					this.currentTime = new Date()
					result.myCases.forEach(pcCase => {
						if(pcCase.CreatedById !== Id && pcCase.OldValue && (pcCase.NewValue.includes('Closed') || pcCase.NewValue === 'Cancelled')) {
							let tempCase = {...pcCase}
							tempCase.show = true
							tempCase.status = pcCase.NewValue.toLowerCase()
							if(this.caseObj.Id === pcCase.CaseId) {
								this.currentClosedCase = tempCase
							}else {
								this.myCases.push(tempCase);
							}
							
						}
					})
				}
			})
			.catch((error) => {
				this.dispatchEvent(
					new ShowToastEvent({
						message: error.body ? error.body.message : error.message,
						title: 'Error occurred trying to retrieve skills list',
						variant: 'error',
						mode: 'sticky'
					})
				);
			});
	}

	handleButtonSelection(event) {
		if (this.selectedSkill !== null && this.channelShort !== null)
			this.skillsAndButtons.find((element) => element.skillName === this.selectedSkill)[this.channelShort].variant =
				'neutral';
		this.selectedSkill = event.target.getAttribute('data-skill');
		this.consultChannel = event.target.getAttribute('data-channel');
		this.channelShort = event.target.getAttribute('data-channel-short');
		this.skillsAndButtons.find((element) => element.skillName === this.selectedSkill)[this.channelShort].variant = 'brand';
	}

	handleCaseDetails(event) {
		this.caseDetails = event.detail.value;
		this.caseDetailsChars = event.detail.value.length;
	}

	handleVeteranMemberId(event) {
		this.veteranMemberId = event.detail.value;
	}

	handleCallback(event) {
		this.callback = event.detail.value
	}

	handleCallbackExt(event) {
		this.callbackExt = event.detail.value
	}

	handleCloseModal() {
		this.resetPage();
	}

	handleCancelCaseModal() {
		this.showSpinner = true;
		cancelCase({caseId: this.caseObj.Id})
		.then( result => {
			getRecordNotifyChange([{recordId: this.caseObj.Id}]);
			this.resetPage()
		})
		.catch( error => {
			this.dispatchEvent(
				new ShowToastEvent({
					message: `${JSON.stringify(error)}`,
					title: 'Error occurred trying to cancel this case',
					variant: 'error',
					mode: 'sticky'
				})
			);
		})
		.finally(() => {
			this.showSpinner = false;
		})
	}

	handleSubmit(event) {

		if (this.consultChannel === 'Phone' && !this.showPhoneModal) {
			this.showPhoneModal = true;
		}
		else {
			this.showSpinner = true;
			this.progressLabel = 'Creating case...'
			this.showPhoneModal = false;
			let combinedCallback = this.callback + (this.callbackExt ? ' Ext. ' + this.callbackExt : '')
			createCase({
				skill: this.selectedSkill,
				details: this.caseDetails,
				memberId: this.veteranMemberId,
				channel: this.consultChannel,
				callback: combinedCallback
			})
				.then((result) => {
					this.progressLabel = 'Routing to consultant...'
					this.caseObj = result;
					try {
						this.waitForRouting()
					} catch (e) {
					}
				})
				.catch(error => {
					this.dispatchEvent(
						new ShowToastEvent({
							message: 'Error occurred trying to create case.',
							variant: 'error',
							mode: 'sticky'
						})
					);
					this.showSpinner = false;
				})
		}
	}

	waitForRouting() {
		this.interval = setInterval(this.getAgent.bind(this), 1000)
	}

	getAgent() {
		getAssignedAgent({ caseId: this.caseObj.Id })
			.then(result => {
				if (result.agent && this.caseObj.Id) {
					this.progressLabel = ''
					//clear recurring apex call to prevent infinite loop
					clearInterval(this.interval)
					this.showSpinner = false;
					this.agent = {...result.agent};
					this.chatId = result.chatId;

					this.showCaseModal = true;
					if(this.isTeams) {
						this.launchTeamsVideo();
					}
					this.dispatchEvent(
						new ShowToastEvent({
							message: 'Your new case is logged 💼, now routing to a matching TeleHealth Provider ...',
							variant: 'success'
						})
					);
				}
			})
			.catch(error => {
			})
	}

	@track countdownInt = 5
	launchTeamsVideo() {
		this.countdownInt = 5;
		this.countdownInterval = setInterval(this.countdown.bind(this), 1000)
	}

	countdown() {
		this.countdownInt--
		if(this.countdownInt <= 0) {
			this.countdownInt = 0
			clearInterval(this.countdownInterval)
			window.open('https://teams.microsoft.com/l/call/0/0?users=' + this.agent.Email, '_blank')
		}
	}

	handleLaunchNow() {
		window.open('https://teams.microsoft.com/l/call/0/0?users=' + this.agent.Email, '_blank')
	}

	openConfirmCancel() {
		this.showConfirmModal = true
		this.showCaseModal = false;
	}
	closeConfirmCancel() {
		this.showConfirmModal = false;
		this.showCaseModal = true;
	}

	handleCloseAlert(event) {
		let alert = this.myCases.find(obj => obj.Id === event.target.dataset.id);
		alert.show = false
	}

	navigateToCase(event) {
		let id = event.target.dataset.id
		this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
				objectApiName: 'Case',
                actionName: 'view',
            },
        })
	}

	resetPage() {
		this.caseObj = {}
		this.currentClosedCase = {}
		this.selectedSkill = null;
		this.consultChannel = null;
		this.channelShort = null;
		this.template.querySelector('[data-id="case-details"]').value = null;
		this.caseDetailsChars = 0;
		this.template.querySelector('[data-id="member-id"]').value = null;

		this.showCaseModal = false;
		this.showConfirmModal = false;
	}
}
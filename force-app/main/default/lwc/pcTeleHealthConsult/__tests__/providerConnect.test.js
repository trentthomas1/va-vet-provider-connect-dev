/* eslint-disable @lwc/lwc/no-inner-html */
import { createElement } from 'lwc';
import ProviderConnect from 'c/pcTeleHealthConsult';
import getSkills from '@salesforce/apex/PC_ProviderConnectController.getSkills';
import createCase from '@salesforce/apex/PC_ProviderConnectController.createCase';
import getAssignedAgent from '@salesforce/apex/PC_ProviderConnectController.getAssignedAgent';
import cancelCase from '@salesforce/apex/PC_ProviderConnectController.cancelCase';
import getChatterMessages from '@salesforce/apex/PC_ChatController.getChatterMessages';
import getChatterMessagesCache from '@salesforce/apex/PC_ChatController.getChatterMessagesCache';


jest.mock('@salesforce/apex/PC_ProviderConnectController.getSkills', () => ({
    default: jest.fn()
}),
    { virtual: true }
)

jest.mock('@salesforce/apex/PC_ProviderConnectController.createCase', () => ({
    default: jest.fn()
}),
    { virtual: true }
)

jest.mock('@salesforce/apex/PC_ProviderConnectController.getAssignedAgent', () => ({
    default: jest.fn()
}),
    { virtual: true }
)


jest.mock('@salesforce/apex/PC_ProviderConnectController.cancelCase', () => ({
    default: jest.fn()
}),
    { virtual: true }
)

jest.mock('@salesforce/apex/PC_ChatController.getChatterMessages', () => ({
    default: jest.fn()
}),
    { virtual: true }
)

jest.mock('@salesforce/apex/PC_ChatController.getChatterMessagesCache', () => ({
    default: jest.fn()
}),
    { virtual: true }
)


jest.useFakeTimers();
jest.spyOn(global, 'setInterval');

describe('c-pc-tele-health-consult', () => {

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    function flushPromises() {
        // eslint-disable-next-line no-undef
        return new Promise((resolve) => setImmediate(resolve));
    }

    test('Get Skills Test', () => {
        const ProviderConnectElement = createElement('c-pc-tele-health-consult', {
            is: ProviderConnect
        });
        const mockDBSuccess = require("./data/getSkillsMock.json");
        getSkills.mockResolvedValue(mockDBSuccess)

        document.body.appendChild(ProviderConnectElement);

        return flushPromises().then(() => {
            const headerElements = ProviderConnectElement.shadowRoot.querySelectorAll('th');
            expect(headerElements.length).toBe(7);
            const chatButton = ProviderConnectElement.shadowRoot.querySelector('[data-skill="Cardiology"][data-channel="Chat"]');
            expect(chatButton.disabled).toBe(false)
        });
    })


    test('Create Chat Case', () => {
        const ProviderConnectElement = createElement('c-pc-tele-health-consult', {
            is: ProviderConnect
        });
        const getSkillsMock = require("./data/getSkillsMock.json");
        getSkills.mockResolvedValue(getSkillsMock)

        const createCaseMock = require("./data/createCaseMock.json");
        createCase.mockResolvedValue(createCaseMock)

        const getAssignedAgentMock = require("./data/getAssignedAgentMock.json");
        getAssignedAgent.mockResolvedValue(getAssignedAgentMock)

        const mockDBSuccess = require("./data/dbSuccessMockOpen.json");
        getChatterMessages.mockResolvedValue(mockDBSuccess);

        const mockCacheSuccess = require("./data/cacheSuccessMock.json");
        getChatterMessagesCache.mockResolvedValue(mockCacheSuccess);

        document.body.appendChild(ProviderConnectElement);

        return flushPromises().then(() => {
            const chatButton = ProviderConnectElement.shadowRoot.querySelector('[data-skill="Cardiology"][data-channel="Chat"]');
            chatButton.dispatchEvent(new CustomEvent('click'));
            return flushPromises().then(() => {
                const createButton = ProviderConnectElement.shadowRoot.querySelectorAll('lightning-button');
                let nextButton = null
                createButton.forEach(button => {
                    if (button.label === 'Next')
                        nextButton = button;
                })
                nextButton.dispatchEvent(new CustomEvent('click'));
                return flushPromises().then(() => {
                    jest.runOnlyPendingTimers();
                    return flushPromises().then(() => {
                        const chatElements = ProviderConnectElement.shadowRoot.querySelectorAll('c-pc-chat');
                        expect(chatElements.length).toBe(1);
                    });
                });
            });
        })
    });


    test('Create Phone Case', () => {
        const ProviderConnectElement = createElement('c-pc-tele-health-consult', {
            is: ProviderConnect
        });
        const getSkillsMock = require("./data/getSkillsMock.json");
        getSkills.mockResolvedValue(getSkillsMock)

        const createCaseMock = require("./data/createCaseMock.json");
        createCase.mockResolvedValue(createCaseMock)

        const getAssignedAgentMock = require("./data/getAssignedAgentMock.json");
        getAssignedAgent.mockResolvedValue(getAssignedAgentMock)

        document.body.appendChild(ProviderConnectElement);

        return flushPromises().then(() => {
            const chatButton = ProviderConnectElement.shadowRoot.querySelector('[data-skill="Cardiology"][data-channel="Phone"]');
            chatButton.dispatchEvent(new CustomEvent('click'));
            return flushPromises().then(() => {
                const createButton = ProviderConnectElement.shadowRoot.querySelectorAll('lightning-button');
                let nextButton = null
                createButton.forEach(button => {
                    if (button.label === 'Next')
                        nextButton = button;
                })
                nextButton.dispatchEvent(new CustomEvent('click'));
                return flushPromises().then(() => {
                    const inputs = ProviderConnectElement.shadowRoot.querySelectorAll('lightning-input');
                    let input = null
                    inputs.forEach(inp => {
                        if (inp.label === "Callback Number:")
                            input = inp;
                    })
                    input.dispatchEvent(new CustomEvent('change', { detail: '111-111-1111' }));
                    const connectButton = ProviderConnectElement.shadowRoot.querySelectorAll('button');
                    let connect = null
                    connectButton.forEach(button => {
                        if (button.innerHTML === 'Connect')
                            connect = button;
                    })
                    connect.dispatchEvent(new CustomEvent('click'));
                    return flushPromises().then(() => {
                        jest.runOnlyPendingTimers();
                        return flushPromises().then(() => {
                            const divElements = ProviderConnectElement.shadowRoot.querySelectorAll('.slds-text-body_regular');
                            let phoneDiv = null
                            divElements.forEach(div => {
                                if (div.innerHTML.includes('The consultant has received your case and will give you a call back'))
                                    phoneDiv = div
                            })
                            expect(Object.keys(phoneDiv).length).toBeGreaterThanOrEqual(1)
                        });
                    });
                });

            });
        })
    });


    test('Create Teams Case', () => {
        const ProviderConnectElement = createElement('c-pc-tele-health-consult', {
            is: ProviderConnect
        });
        const getSkillsMock = require("./data/getSkillsMock.json");
        getSkills.mockResolvedValue(getSkillsMock)

        const createCaseMock = require("./data/createCaseMock.json");
        createCase.mockResolvedValue(createCaseMock)

        const getAssignedAgentMock = require("./data/getAssignedAgentMock.json");
        getAssignedAgent.mockResolvedValue(getAssignedAgentMock)

        document.body.appendChild(ProviderConnectElement);

        return flushPromises().then(() => {
            const chatButton = ProviderConnectElement.shadowRoot.querySelector('[data-skill="Cardiology"][data-channel="Teams"]');
            chatButton.dispatchEvent(new CustomEvent('click'));
            return flushPromises().then(() => {
                const createButton = ProviderConnectElement.shadowRoot.querySelectorAll('lightning-button');
                let nextButton = null
                createButton.forEach(button => {
                    if (button.label === 'Next')
                        nextButton = button;
                })
                nextButton.dispatchEvent(new CustomEvent('click'));
                return flushPromises().then(() => {
                    jest.runOnlyPendingTimers();
                    return flushPromises().then(() => {
                        const pElements = ProviderConnectElement.shadowRoot.querySelectorAll('p');
                        let teams = null
                        pElements.forEach(p => {
                            if (p.innerHTML.includes('Redirecting to Teams video call'))
                                teams = p
                        })
                        expect(Object.keys(teams).length).toBeGreaterThanOrEqual(1)
                    });

                });

            });
        })
    });

    test('Cancel Case', () => {
        const ProviderConnectElement = createElement('c-pc-tele-health-consult', {
            is: ProviderConnect
        });

        const toastEventHandler = jest.fn()
        ProviderConnectElement.addEventListener('lightning__showtoast', toastEventHandler)

        const getSkillsMock = require("./data/getSkillsMock.json");
        getSkills.mockResolvedValue(getSkillsMock)

        const createCaseMock = require("./data/createCaseMock.json");
        createCase.mockResolvedValue(createCaseMock)

        const getAssignedAgentMock = require("./data/getAssignedAgentMock.json");
        getAssignedAgent.mockResolvedValue(getAssignedAgentMock)

        const cancelCaseMock = require("./data/cancelCaseMock.json");
        cancelCase.mockResolvedValue(cancelCaseMock)

        document.body.appendChild(ProviderConnectElement);

        return flushPromises().then(() => {
            const chatButton = ProviderConnectElement.shadowRoot.querySelector('[data-skill="Cardiology"][data-channel="Teams"]');
            chatButton.dispatchEvent(new CustomEvent('click'));
            return flushPromises().then(() => {
                const createButton = ProviderConnectElement.shadowRoot.querySelectorAll('lightning-button');
                let nextButton = null
                createButton.forEach(button => {
                    if (button.label === 'Next')
                        nextButton = button;
                })
                nextButton.dispatchEvent(new CustomEvent('click'));
                return flushPromises().then(() => {
                    jest.runOnlyPendingTimers();
                    return flushPromises().then(() => {
                        const aElements = ProviderConnectElement.shadowRoot.querySelectorAll('a');
                        let cancel = null
                        aElements.forEach(a => {
                            if (a.innerHTML.includes('Cancel Case'))
                                cancel = a
                        })
                        cancel.dispatchEvent(new CustomEvent('click'))
                        return flushPromises().then(() => {
                            let buttonElements = ProviderConnectElement.shadowRoot.querySelectorAll('button');
                            let confirmCancel = null
                            buttonElements.forEach(button => {
                                if (button.innerHTML.includes('Cancel Case'))
                                    confirmCancel = button
                            })
                            confirmCancel.dispatchEvent(new CustomEvent('click'));
                            return flushPromises().then(() => {
                                buttonElements = ProviderConnectElement.shadowRoot.querySelectorAll('button');
                                confirmCancel = null
                                buttonElements.forEach(button => {
                                    if (button.innerHTML.includes('Cancel Case'))
                                        confirmCancel = button
                                })

                                //getRecordNotifyChange not included in jest, testing for negative instead
                                expect(toastEventHandler).toBeCalled()
                            });
                        });

                    });

                });
            })
        });
    })
})
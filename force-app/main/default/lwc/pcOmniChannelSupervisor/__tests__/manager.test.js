import { createElement } from 'lwc';
import manager from 'c/pcOmniChannelSupervisor';
import getAgentHistory from '@salesforce/apex/PC_ManagerController.getAgentHistory';

jest.mock('@salesforce/apex/PC_ManagerController.getAgentHistory', () => ({
    default: jest.fn()
}),
    {virtual:true}
)

describe('c-pc-omni-channel-supervisor', () => {

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


    test('Check Agent History', () => {
        const ManagerElement = createElement('c-pc-omni-channel-supervisor', {
            is: manager
        });

        const toastEventHandler = jest.fn()
        // add the event listener to the component
        ManagerElement.addEventListener('lightning__showtoast', toastEventHandler)

        const mockDBSuccess = require("./data/getAgentHistoryMock.json");
        getAgentHistory.mockResolvedValue(mockDBSuccess);

        
        document.body.appendChild(ManagerElement);

        
        const tabs = ManagerElement.shadowRoot.querySelectorAll('lightning-tab');
        expect(tabs.length).toBe(2);

        return flushPromises().then(() => {
            console.log(ManagerElement.agentStatus);
            const users = ManagerElement.shadowRoot.querySelectorAll('div.user-container');
            expect(users.length).toBe(9);
        });
        
    })

})
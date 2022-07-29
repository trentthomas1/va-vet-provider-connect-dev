import { createElement } from 'lwc';
import ChannelSelection from 'c/pcChannelSelection';
import getChannelAvailability from '@salesforce/apex/PC_ProviderConnectController.getChannelAvailability';
import setChannelAvailability from '@salesforce/apex/PC_ProviderConnectController.setChannelAvailability';

describe('c-pc-channel-selection', () => {

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    test('Get Channel Selection', () => {
        const ChannelSelectionElement = createElement('c-pc-channel-selection', {
            is: ChannelSelection
        });
        document.body.appendChild(ChannelSelectionElement);

        const mockSuccess = require("./data/getChannelSelectionSuccessMock.json");
        getChannelAvailability.mockResolvedValue(mockSuccess);

        const channelButton = ChannelSelectionElement.shadowRoot.querySelectorAll('lightning-button');

        return Promise.resolve().then(() => {
            expect(channelButton.length).toBe(3);
        })
    });

    test('Set Channel Selection', () => {
        const ChannelSelectionElement = createElement('c-pc-channel-selection', {
            is: ChannelSelection
        });

        const toastEventHandler = jest.fn()
        ChannelSelectionElement.addEventListener('lightning__showtoast', toastEventHandler)

        document.body.appendChild(ChannelSelectionElement);

        const getMockSuccess = require("./data/getChannelSelectionSuccessMock.json");
        getChannelAvailability.mockResolvedValue(getMockSuccess);

        const setMockSuccess = require("./data/setChannelSelectionSuccessMock.json");
        setChannelAvailability.mockResolvedValue(setMockSuccess);

        const channelButton = ChannelSelectionElement.shadowRoot.querySelectorAll('lightning-button');

        return Promise.resolve().then(() => {
            channelButton[0].dispatchEvent(new CustomEvent('click'));
          
            return Promise.resolve().then(() => {
                expect(toastEventHandler).toHaveBeenCalled();
            });
        })
    });
});
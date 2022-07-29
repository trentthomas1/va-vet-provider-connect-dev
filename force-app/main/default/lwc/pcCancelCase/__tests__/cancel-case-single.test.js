import { createElement } from 'lwc';
import CancelCase from 'c/pcCancelCase';
import cancelCase from '@salesforce/apex/PC_ProviderConnectController.cancelCase';

jest.mock(
    "@salesforce/apex/PC_ProviderConnectController.cancelCase",
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

describe('c-pc-cancel-case', () => {

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    test('Cancel Case button opens confirmation', () => {
        const CancelCaseElement = createElement('c-pc-cancel-case', {
            is: CancelCase
        });
        document.body.appendChild(CancelCaseElement);

        const cancelButton = CancelCaseElement.shadowRoot.querySelector('button');

        cancelButton.dispatchEvent(new CustomEvent('click'));
          
        return Promise.resolve().then(() => {
            const confirmButtons = CancelCaseElement.shadowRoot.querySelectorAll('button');
            expect(confirmButtons.length).toBe(3);
        });
    });

    test('Do not cancel case', () => {
        const CancelCaseElement = createElement('c-pc-cancel-case', {
            is: CancelCase
        });
        document.body.appendChild(CancelCaseElement);

        const cancelButton = CancelCaseElement.shadowRoot.querySelector('button');
        
        cancelButton.dispatchEvent(new CustomEvent('click'));
          
        return Promise.resolve().then(() => {
            const dontCancel = CancelCaseElement.shadowRoot.querySelector('[data-id="doNotCancelButton"]');
            dontCancel.dispatchEvent(new CustomEvent('click'));
            return Promise.resolve().then(() => {
                const confirmButtons = CancelCaseElement.shadowRoot.querySelectorAll('button');
                expect(confirmButtons.length).toBe(1);
            })
        });
    });


    test('Confirm Cancel Case', () => {
        const CancelCaseElement = createElement('c-pc-cancel-case', {
            is: CancelCase
        });

        const toastEventHandler = jest.fn()
        CancelCaseElement.addEventListener('lightning__showtoast', toastEventHandler)
        
        document.body.appendChild(CancelCaseElement);

        const cancelButton = CancelCaseElement.shadowRoot.querySelector('button');
        const mockSuccess = require("./data/cancelCaseSuccessMock.json");

        cancelCase.mockResolvedValue(mockSuccess);
        cancelButton.dispatchEvent(new CustomEvent('click'));
          
        return Promise.resolve().then(() => {
            const cancelAllButton = CancelCaseElement.shadowRoot.querySelector('[data-id="cancelAllButton"]');
            cancelAllButton.dispatchEvent(new CustomEvent('click'));
            
            return Promise.resolve().then(() => {
                expect(toastEventHandler).toHaveBeenCalled();
            })

        });
    
    })
});
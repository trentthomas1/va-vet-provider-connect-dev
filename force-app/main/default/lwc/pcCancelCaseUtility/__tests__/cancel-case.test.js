import { createElement } from 'lwc';
import CancelCase from 'c/pcCancelCaseUtility';
import cancelOpenCases from '@salesforce/apex/PC_ProviderConnectController.cancelOpenCases';

jest.mock(
    "@salesforce/apex/PC_ProviderConnectController.cancelOpenCases",
    () => {
        return {
            default: jest.fn(payload => {
                const response = payload.records.map((record, index) => {
                    return Object.assign({ Id: "TEST_ID" + index }, record);
                });
                return response;
            })
        };
    },
    { virtual: true }
);


// const mockDataEmpty = require('./data/cancelCasesEmptyMock.json');
// const mockDataSuccess = require('./data/cancelCasesSuccessMock.json');

describe('c-pc-cancel-case-utility', () => {

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    test('Text change should enable button', () => {
        const CancelCaseElement = createElement('c-pc-cancel-case-utility', {
            is: CancelCase
        });
        document.body.appendChild(CancelCaseElement);

        const cancelButton = CancelCaseElement.shadowRoot.querySelector('[data-id="cancelButton"]');
        expect(cancelButton.disabled).toBe(true);

        const textElement = CancelCaseElement.shadowRoot.querySelector('[data-id="cancelReason"]');

        textElement.value = 'test reason';
        textElement.dispatchEvent(new CustomEvent('change'));
          
        return Promise.resolve().then(() => {
            expect(cancelButton.disabled).toBe(false);
        });
    });

    test('Cancel All Cases button opens confirmation', () => {
        const CancelCaseElement = createElement('c-pc-cancel-case-utility', {
            is: CancelCase
        });
        document.body.appendChild(CancelCaseElement);

        const cancelButton = CancelCaseElement.shadowRoot.querySelector('[data-id="cancelButton"]');

        cancelButton.dispatchEvent(new CustomEvent('click'));
          
        return Promise.resolve().then(() => {
            const confirmButtons = CancelCaseElement.shadowRoot.querySelectorAll('button');
            expect(confirmButtons.length).toBe(2);
        });
    });

    test('Do not cancel cases', () => {
        const CancelCaseElement = createElement('c-pc-cancel-case-utility', {
            is: CancelCase
        });
        document.body.appendChild(CancelCaseElement);

        const cancelButton = CancelCaseElement.shadowRoot.querySelector('[data-id="cancelButton"]');
        
        cancelButton.dispatchEvent(new CustomEvent('click'));
          
        return Promise.resolve().then(() => {
            const dontCancel = CancelCaseElement.shadowRoot.querySelector('[data-id="doNotCancelButton"]');
            dontCancel.dispatchEvent(new CustomEvent('click'));
            return Promise.resolve().then(() => {
                const textElement = CancelCaseElement.shadowRoot.querySelector('[data-id="cancelReason"]');
                expect(textElement).toBeTruthy();
            })
        });
    });


    test('Confirm Cancel All Cases', () => {
        const CancelCaseElement = createElement('c-pc-cancel-case-utility', {
            is: CancelCase
        });

        const toastEventHandler = jest.fn()
        // add the event listener to the component
        comp.addEventListener(ShowToastEventName, toastEventHandler)
        
        document.body.appendChild(CancelCaseElement);

        const cancelButton = CancelCaseElement.shadowRoot.querySelector('[data-id="cancelButton"]');
        
        cancelButton.dispatchEvent(new CustomEvent('click'));
          
        return Promise.resolve().then(() => {
            const cancelAllButton = CancelCaseElement.shadowRoot.querySelector('[data-id="cancelButton"]');
            cancelAllButton.dispatchEvent(new CustomEvent('click'));
            
            return Promise.resolve().then(() => {
                expect(doCheckIn).toHaveBeenCalled()
            })

        });
    
    })
});
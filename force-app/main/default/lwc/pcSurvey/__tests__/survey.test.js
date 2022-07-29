import { createElement } from 'lwc';
import Survey from 'c/pcSurvey';
import getSurvey from '@salesforce/apex/PC_SurveyController.getSurvey';
import saveSurvey from '@salesforce/apex/PC_SurveyController.saveSurvey';

jest.mock('@salesforce/apex/PC_SurveyController.getSurvey',() => {
        const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
        return {
            default: createApexTestWireAdapter(jest.fn()),
        };
    },
    { virtual: true }
);

jest.mock('@salesforce/apex/PC_SurveyController.saveSurvey', () => ({
    default: jest.fn()
}),
    { virtual: true }
)


describe('c-pc-survey', () => {

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

    test('Get Survey', () => {
        const SurveyElement = createElement('c-pc-survey', {
            is: Survey
        });

        SurveyElement.recordId = '12345'
        
        document.body.appendChild(SurveyElement);

        const mockDBSuccess = require("./data/SurveyMock.json");

        getSurvey.emit(mockDBSuccess)
          
        return flushPromises().then(() => {
            const inputElement = SurveyElement.shadowRoot.querySelectorAll('input');
            let counter = 0;
            inputElement.forEach(input => {
                if(input.checked)
                    counter++
            })
            expect(counter).toBe(3);
        });
    })

    
    test('Set Survey', () => {
        const SurveyElement = createElement('c-pc-survey', {
            is: Survey
        });
        
        const toastEventHandler = jest.fn()
        SurveyElement.addEventListener('lightning__showtoast', toastEventHandler)

        SurveyElement.recordId = '12345'
        
        document.body.appendChild(SurveyElement);

        const mockDBSuccess = require("./data/SurveyMock.json");

        getSurvey.emit(mockDBSuccess)

        saveSurvey.mockResolvedValue(mockDBSuccess);
          
        return flushPromises().then(() => {
            const inputElement = SurveyElement.shadowRoot.querySelectorAll('input');
            inputElement[3].checked = true;
            inputElement[3].value = true;
            inputElement[3].dispatchEvent(new CustomEvent('change'));

            return flushPromises().then(() => {
                expect(toastEventHandler).toBeCalled();
            });
        });
    })

})
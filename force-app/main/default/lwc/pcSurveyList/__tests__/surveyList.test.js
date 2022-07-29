import { createElement } from 'lwc';
import SurveyList from 'c/pcSurveyList';
import getSurveysToComplete from '@salesforce/apex/PC_SurveyController.getSurveysToComplete';

jest.mock('@salesforce/apex/PC_SurveyController.getSurveysToComplete', () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
        default: createApexTestWireAdapter(jest.fn()),
    };
},
    { virtual: true }
);


describe('c-pc-survey-list', () => {

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

    test('Get Survey List Populated', () => {
        const SurveyListElement = createElement('c-pc-survey-list', {
            is: SurveyList
        });

        document.body.appendChild(SurveyListElement);

        const mockDBSuccess = require("./data/popList.json");

        getSurveysToComplete.emit(mockDBSuccess)

        return flushPromises().then(() => {
            const dtElement = SurveyListElement.shadowRoot.querySelectorAll('lightning-datatable');
            expect(dtElement.length).toBe(1);
            const messageElement = SurveyListElement.shadowRoot.querySelectorAll('.empty-list-message');
            expect(messageElement.length).toBe(0);
        });
    })

    test('Get Survey List Empty', () => {
        const SurveyListElement = createElement('c-pc-survey-list', {
            is: SurveyList
        });

        document.body.appendChild(SurveyListElement);

        const mockDBSuccess = require("./data/emptyList.json");

        getSurveysToComplete.emit(mockDBSuccess)

        return flushPromises().then(() => {
            const dtElement = SurveyListElement.shadowRoot.querySelectorAll('lightning-datatable');
            expect(dtElement.length).toBe(0);

            const messageElement = SurveyListElement.shadowRoot.querySelectorAll('.empty-list-message');
            expect(messageElement.length).toBe(1);
        });
    })
})
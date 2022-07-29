import { createElement } from 'lwc';
import Feedback from 'c/pcFeedback';

describe('c-pc-feedback', () => {

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    test('Send Feedback', () => {
        const FeedbackElement = createElement('c-pc-feedback', {
            is: Feedback
        });

        const toastEventHandler = jest.fn()
        // add the event listener to the component
        FeedbackElement.addEventListener('lightning__showtoast', toastEventHandler)
        
        document.body.appendChild(FeedbackElement);

        let textElement = FeedbackElement.shadowRoot.querySelector('lightning-textarea');

        textElement.value = 'test feedback';
        textElement.dispatchEvent(new CustomEvent('change'));

        let submitButton = FeedbackElement.shadowRoot.querySelector('lightning-button');
    
        submitButton.dispatchEvent(new CustomEvent('click'));
          
        return Promise.resolve().then(() => {
            expect(toastEventHandler).toHaveBeenCalled();
        });
    
    })

})
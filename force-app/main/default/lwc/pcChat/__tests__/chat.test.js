import { createElement } from 'lwc';
import Chat from 'c/pcChat';
import getChatterMessages from '@salesforce/apex/PC_ChatController.getChatterMessages';
import getChatterMessagesCache from '@salesforce/apex/PC_ChatController.getChatterMessagesCache';
import saveChatterMessage from '@salesforce/apex/PC_ChatController.saveChatterMessage';
import closeChatSession from '@salesforce/apex/PC_ChatController.closeChatSession';

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

jest.mock('@salesforce/apex/PC_ChatController.saveChatterMessage', () => ({
    default: jest.fn()
}),
    { virtual: true }
)

jest.mock('@salesforce/apex/PC_ChatController.closeChatSession', () => ({
    default: jest.fn()
}),
    { virtual: true }
)



describe('c-pc-chat', () => {

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

    test('Get Chatter Messages', () => {
        const ChatElement = createElement('c-pc-chat', {
            is: Chat
        });

        ChatElement.sessionId = '12345';

        const mockDBSuccess = require("./data/dbSuccessMockOpen.json");
        getChatterMessages.mockResolvedValue(mockDBSuccess);

        const mockCacheSuccess = require("./data/cacheSuccessMock.json");
        getChatterMessagesCache.mockResolvedValue(mockCacheSuccess);

        document.body.appendChild(ChatElement);

        return flushPromises().then(() => {
            const messages = ChatElement.shadowRoot.querySelectorAll('lightning-formatted-rich-text');
            console.log(messages);
            expect(messages.length).toBe(2);
        })
    });

    test('Set Chat Message', () => {
        const ChatElement = createElement('c-pc-chat', {
            is: Chat
        });

        const toastEventHandler = jest.fn()
        ChatElement.addEventListener('lightning__showtoast', toastEventHandler)

        ChatElement.sessionId = '12345';

        const mockDBSuccess = require("./data/dbSuccessMockOpen.json");
        getChatterMessages.mockResolvedValue(mockDBSuccess);

        const mockCacheSuccess = require("./data/cacheSuccessMock.json");
        getChatterMessagesCache.mockResolvedValue(mockCacheSuccess);

        const mockSetSuccess = require("./data/setMessageSuccess.json");
        saveChatterMessage.mockResolvedValue(mockSetSuccess);

        document.body.appendChild(ChatElement);

        return flushPromises().then(() => {

            let textElement = ChatElement.shadowRoot.querySelector('[data-id="textarea"]');

            textElement.value = 'test chat';
            textElement.dispatchEvent(new CustomEvent('change'));

            return flushPromises().then(() => {
                const chatButton = ChatElement.shadowRoot.querySelector('[data-id="button"]');
                chatButton.dispatchEvent(new CustomEvent('click'));

                return flushPromises().then(() => {
                    expect(textElement.value).toBe('');
                });
            });
        })
    });

    test('Close Chat', () => {
        const ChatElement = createElement('c-pc-chat', {
            is: Chat
        });

        const toastEventHandler = jest.fn()
        ChatElement.addEventListener('lightning__showtoast', toastEventHandler)

        ChatElement.sessionId = '12345';

        const mockDBSuccess = require("./data/dbSuccessMockOpen.json");
        getChatterMessages.mockResolvedValue(mockDBSuccess);

        const mockDBSuccessClosed = require("./data/dbSuccessMockClosed.json");
        closeChatSession.mockResolvedValue(mockDBSuccessClosed);

        const mockCacheSuccess = require("./data/cacheSuccessMock.json");
        getChatterMessagesCache.mockResolvedValue(mockCacheSuccess);

        document.body.appendChild(ChatElement);

        return flushPromises().then(() => {
            let endButton = ChatElement.shadowRoot.querySelector('lightning-button');
            endButton.dispatchEvent(new CustomEvent('click'));

            return flushPromises().then(() => {
                endButton = ChatElement.shadowRoot.querySelector('lightning-button');
                expect(endButton).toBe(null);
            })
        })
    });
});
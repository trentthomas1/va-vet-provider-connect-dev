/**
 * @description       : Test class for PC_ChatController
 * @author            : George Elias
 * @group             : Booze Allen Hamilton
 * @last modified on  : 07-06-2022
 * @last modified by  : George Elias
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-06-2022   George Elias                          Initial Version
 **/
@isTest
public class PC_ChatControllerTest {

    /**
    * @description Method to create test data for unit tests
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @TestSetup
    static void makeData(){
        Case c = PC_ProviderConnectController.createCase('Cardiology', 'Test Details', '987654321', 'Chat', '1234567890');
    }
    
    /**
    * @description Method to test getChatterMessages method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    public static void getChatterMessagesTest() {
        Case c = [SELECT ID FROM Case LIMIT 1];

        PC_Chat_Session__c session = [SELECT Id FROM PC_Chat_Session__c WHERE PC_Case__c = :c.Id];

        insert new FeedItem(ParentId=session.Id, Type='TextPost', Body='Test', IsRichText = false, NetworkScope='AllNetworks', Visibility='InternalUsers', Status='Published');

        PC_Chat_Session__c returnSession = PC_ChatController.getChatterMessages(session.Id, null, '');
        
        System.assert(returnSession.Feeds.size() == 1);

        returnSession = PC_ChatController.getChatterMessages(null, c.Id, '');
        
        System.assert(returnSession.Feeds.size() == 1);
    }


    /**
    * @description Method to test getChatterMessagesCache method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    public static void getChatterMessagesCacheTest() {
        Case c = [SELECT ID FROM Case LIMIT 1];

        PC_Chat_Session__c session = [SELECT Id FROM PC_Chat_Session__c WHERE PC_Case__c = :c.Id];

        insert new FeedItem(ParentId=session.Id, Type='TextPost', Body='Test', IsRichText = false, NetworkScope='AllNetworks', Visibility='InternalUsers', Status='Published');
        
        //Without Cache
        PC_CacheResults returnSession = PC_ChatController.getChatterMessagesCache(session.Id, '');
        
        System.assert(returnSession.chatList.size() == 1, returnSession.chatList.size());
        
		PC_ChatController.saveChatterMessage(session.Id, 'Test');
        
        //With Cache
        returnSession = PC_ChatController.getChatterMessagesCache(session.Id, '');
        
        System.assert(returnSession.chatList.size() == 1, returnSession.chatList.size());
    }


    /**
    * @description Method to test saveChatterMessage method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    public static void saveChatterMessageTest() {
        Case c = [SELECT ID FROM Case LIMIT 1];

        PC_Chat_Session__c session = [SELECT Id FROM PC_Chat_Session__c WHERE PC_Case__c = :c.Id];

        PC_ChatController.saveChatterMessage(session.Id, 'Test');

        List<PC_Chat_Session__Feed> feed = [SELECT Id FROM PC_Chat_Session__Feed WHERE ParentId = : session.Id];

        System.assert(feed.size() == 1, feed.size());
    }

    /**
    * @description Method to test closeChatSession method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    public static void closeChatSessionTest() {
        Case c = [SELECT ID FROM Case LIMIT 1];

        PC_Chat_Session__c session = [SELECT Id, PC_Is_Closed__c FROM PC_Chat_Session__c WHERE PC_Case__c = :c.Id];

        System.assertEquals(false, session.PC_Is_Closed__c);

        PC_Chat_Session__c returnSession = PC_ChatController.closeChatSession(session.Id);

        System.assertEquals(true, returnSession.PC_Is_Closed__c);

        session = [SELECT Id, PC_Is_Closed__c FROM PC_Chat_Session__c WHERE PC_Case__c = :c.Id];
        
        System.assertEquals(true, session.PC_Is_Closed__c);

    }
}
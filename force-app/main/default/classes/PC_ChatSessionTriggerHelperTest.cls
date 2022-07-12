/**
 * @description       : Test class for PC_ChatSessionTriggerHelper
 * @author            : George Elias
 * @group             : Booze Allen Hamilton
 * @last modified on  : 07-06-2022
 * @last modified by  : George Elias
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-06-2022   George Elias                          Initial Version
 **/
@IsTest
public class PC_ChatSessionTriggerHelperTest {

    /**
    * @description Method to create test data for unit tests
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @TestSetup
    static void makeData(){
        Case c = PC_ProviderConnectController.createCase('Cardiology', 'Test Details', '987654321', 'Chat', '1234567890');
        PC_Chat_Session__c chatSession = [SELECT Id FROM PC_Chat_Session__c LIMIT 1];
        PC_ChatController.saveChatterMessage(chatSession.Id, 'Test');
    }

    /**
    * @description Method to positively test clearSessionCacheData method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    public static void clearSessionCacheDataTestPositive(){
        PC_Chat_Session__c chatSession = [SELECT Id FROM PC_Chat_Session__c LIMIT 1];
        chatSession.PC_Is_Closed__c = true;
        update chatSession;
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.pcChat');
        System.assertEquals(false, orgPart.contains(chatSession.Id));
    }

    /**
    * @description Method to negatively test clearSessionCacheData method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    public static void clearSessionCacheDataTestNegative() {
        try {
            PC_ChatSessionTriggerHelper.clearSessionCacheData(new List<PC_Chat_Session__c>{new PC_Chat_Session__c()});
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }

    }
}

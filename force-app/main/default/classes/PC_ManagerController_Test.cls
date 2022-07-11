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
@isTest
public class PC_ManagerController_Test {

    /**
    * @description Method to create test data for unit tests
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @TestSetup
    static void makeData(){
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true limit 1];
        List<String> channels = new List<String>{'Chat', 'Teams', 'Phone'};
        for(Skill s : [SELECT Id, MasterLabel FROM Skill WHERE MasterLabel NOT in :channels limit 5]) {
            User pcManager = new User();

            System.runAs(admin){
                pcManager = PC_TestDataFactory.createManager('Test PC Manager'); 
            }

            ServiceResource pcSR = PC_TestDataFactory.createServiceResource(pcManager.Id, pcManager.LastName, s.MasterLabel);

            List<Skill> lsChannelSKills = [SELECT Id FROM Skill WHERE MasterLabel in :channels limit 3];

            PC_TestDataFactory.createServiceResourceSkill(pcSR.Id, lsChannelSKills[0].Id);
            PC_TestDataFactory.createServiceResourceSkill(pcSR.Id, lsChannelSKills[1].Id);
            PC_TestDataFactory.createServiceResourceSkill(pcSR.Id, lsChannelSKills[2].Id);
        }

        User manager = [SELECT Id FROM User WHERE LastName = 'Test PC Manager' LIMIT 1];

        ServicePresenceStatus  sps = [SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = 'PC_Available_Provider_Connect' LIMIT 1];

        UserServicePresence usp = new UserServicePresence(UserId = manager.Id, ServicePresenceStatusId = sps.Id);
        insert usp;

        Case cOpen = PC_ProviderConnectController.createCase('Cardiology', 'Test Details', '987654321', 'Chat', '1234567890');
        Case cClosed = PC_ProviderConnectController.createCase('Cardiology', 'Test Details', '987654321', 'Chat', '1234567890');
        
        PC_TestDataFactory.mockCaseCriteriaSharing(new List<Case> {cOpen, cClosed}, manager.Id);

        Id pcRtId = Schema.SObjectType.ServiceResource.getRecordTypeInfosByName().get('Provider Connect Resource').getRecordTypeId();
        PC_TestDataFactory.mockResourceCriteriaSharing([SELECT Id, CreatedById FROM ServiceResource WHERE RecordTypeId = :pcRtId], manager.Id);
        
        cOpen.OwnerId = manager.Id;
        cClosed.OwnerId = manager.Id;
        cClosed.Status = 'Closed - Resolved';
        update cOpen;
        update cClosed;  
    }

    /**
    * @description Method to test getAgentHistory method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    public static void getAgentHistoryTest() {

        User manager = [SELECT Id FROM User WHERE LastName = 'Test PC Manager' LIMIT 1];
        System.runAs(manager) {
            List<PC_ManagerController.AgentHistory> lsAH = PC_ManagerController.getAgentHistory();
            System.assert(lsAH[0].agentId == manager.Id);
        }
    }
}

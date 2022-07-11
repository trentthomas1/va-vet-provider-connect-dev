/**
 * @description       : Test class for PC_ProviderConnectController
 * @author            : George Elias
 * @group             : Booze Allen Hamilton
 * @last modified on  : 07-06-2022
 * @last modified by  : George Elias
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-06-2022   George Elias                          Initial Version
 **/
@isTest
public class PC_ProviderConnectController_Test {

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
            User pcSpecialist = new User();
            User pcProvider = new User();
            System.runAs(admin){
                pcSpecialist = PC_TestDataFactory.createSpecialist('Test PC Specialist'); 
                pcProvider = PC_TestDataFactory.createProvider('Test PC Provider');
            }
            ServiceResource pcSR = PC_TestDataFactory.createServiceResource(pcSpecialist.Id, pcSpecialist.LastName, s.MasterLabel);
            // ServiceResourceSkill pcSRS = PC_TestDataFactory.createServiceResourceSkill(pcSR.Id, s.Id);

            List<Skill> lsChannelSKills = [SELECT Id FROM Skill WHERE MasterLabel in :channels limit 3];

            PC_TestDataFactory.createServiceResourceSkill(pcSR.Id, lsChannelSKills[0].Id);
            PC_TestDataFactory.createServiceResourceSkill(pcSR.Id, lsChannelSKills[1].Id);
            PC_TestDataFactory.createServiceResourceSkill(pcSR.Id, lsChannelSKills[2].Id);
        }

        User specialist = [SELECT Id FROM User WHERE LastName = 'Test PC Specialist' LIMIT 1];

        ServicePresenceStatus  sps = [SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = 'PC_Available_Provider_Connect' LIMIT 1];

        UserServicePresence usp = new UserServicePresence(UserId = specialist.Id, ServicePresenceStatusId = sps.Id);

        insert usp;
    }

    /**
    * @description Method to test getSkills method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void getSkillsTest(){
        User provider = [SELECT Id FROM User WHERE LastName = 'Test PC Provider' LIMIT 1];
        System.runAs(provider){
            Map<String,Object> skillStatus = PC_ProviderConnectController.getSkills('2022-10-10T14:48:00');
            System.assertEquals(5, ( (List<Object>) skillStatus.get('statuses')).size());
        }
    }


    /**
    * @description Method to test getChannelAvailability method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void getChannelAvailabilityTest(){
        User specialist = [SELECT Id FROM User WHERE LastName = 'Test PC Specialist' LIMIT 1];
        System.runAs(specialist){
            PC_ProviderConnectController.AvailableChannels channels = PC_ProviderConnectController.getChannelAvailability();
            Boolean checkAvailable = channels.chat == true && channels.teams == true && channels.phone == true;
            System.assertEquals(true, checkAvailable); //all channels are available be default
        }
    }


    /**
    * @description Method to test setChannelAvailability method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void setChannelAvailabilityTest(){
        User specialist = [SELECT Id FROM User WHERE LastName = 'Test PC Specialist' LIMIT 1];
        System.runAs(specialist){
            PC_ProviderConnectController.setChannelAvailability('phone', false);
            PC_ProviderConnectController.AvailableChannels channels = PC_ProviderConnectController.getChannelAvailability();
            Boolean checkAvailable = channels.chat == true && channels.teams == true && channels.phone == false;
            System.assertEquals(true, checkAvailable);

            PC_ProviderConnectController.setChannelAvailability('phone', true);
            channels = PC_ProviderConnectController.getChannelAvailability();
            checkAvailable = channels.chat == true && channels.teams == true && channels.phone == true;
            System.assertEquals(true, checkAvailable);
        }
    }

    /**
    * @description Method to test createCase method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void createCaseTest(){
        Case c = PC_ProviderConnectController.createCase('Cardiology', 'Test Details', '987654321', 'Chat', '1234567890');

        List<Case> lsCase = [SELECT Id FROM Case];

        System.assertEquals(1, lsCase.size());
    }

    /**
    * @description Method to test getAssignedAgent method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void getAgentTest() {
        Case c = PC_ProviderConnectController.createCase('Cardiology', 'Test Details', '987654321', 'Chat', '1234567890');
        User provider = [SELECT Id FROM User WHERE LastName = 'Test PC Provider' LIMIT 1];

        System.runAs(provider) {
            Test.startTest();
            Map<String, Object> results = PC_ProviderConnectController.getAssignedAgent(c.Id);
            System.assert(results != null);
            Test.stopTest();
        }
    }


    /**
    * @description Method to test cancelCase method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void cancelCaseTest() {
        User provider = [SELECT Id FROM User WHERE LastName = 'Test PC Provider' LIMIT 1];
        System.runAs(provider) {
            Case c = PC_ProviderConnectController.createCase('Cardiology', 'Test Details', '987654321', 'Chat', '1234567890');
            Test.startTest();
            PC_ProviderConnectController.cancelCase(c.Id);
            Test.stopTest();
            c = [SELECT Id, Status FROM Case WHERE Id = :c.Id];
            System.assertEquals('Cancelled', c.Status);
        }
    }

    /**
    * @description Method to test cancelOpenCases method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void cancelOpenCasesTest() {
        User specialist = [SELECT Id FROM User WHERE LastName = 'Test PC Specialist' LIMIT 1];
        System.runAs(specialist) {
            Case c1 = PC_ProviderConnectController.createCase('Cardiology', 'Test Details', '987654321', 'Chat', '1234567890');
            Case c2 = PC_ProviderConnectController.createCase('Neurology', 'Test Details', '987654321', 'Chat', '1234567890');

            Test.startTest();
            PC_ProviderConnectController.cancelOpenCases('Test Reason');
            Test.stopTest();
            List<String> lsIds = new List<String> {c1.Id, c2.Id};
            List<Case> lsCases = [SELECT Id, IsClosed FROM Case WHERE Id in :lsIds];
            for(Case c : lsCases) {
                System.assertEquals(true, c.IsClosed);
            }
        }
    }

}
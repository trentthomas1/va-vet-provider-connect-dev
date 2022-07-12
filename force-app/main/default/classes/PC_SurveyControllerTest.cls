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
public class PC_SurveyControllerTest {

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
    }

    /**
    * @description Method to test getSurvey method as a provider
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void getSurveyProviderTest(){
        User provider = [SELECT Id FROM User WHERE LastName = 'Test PC Provider' LIMIT 1];
        System.runAs(provider){
            Case c = new Case(
                RecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PC_Case').getRecordTypeId(),
                Description = 'Test',
                Subject ='Test',
                Type = 'Cardiology',
                PC_Channel__c = 'Chat',
                PC_Specialty__c = 'Cardiology'
            );
            
            insert c;

            PC_Survey__c survey = PC_SurveyController.getSurvey(c.Id); //returns survey with no Id

            survey.PC_Was_this_session_useful__c = '5';

            insert survey;

            survey = PC_SurveyController.getSurvey(c.Id);

            system.assertEquals('5', survey.PC_Was_this_session_useful__c); 
        }
    }

    /**
    * @description Method to test getSurvey method as a specialist
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void getSurveySpecialistTest(){
        User specialist = [SELECT Id FROM User WHERE LastName = 'Test PC Specialist' LIMIT 1];
        System.runAs(specialist){
            Case c = new Case(
                RecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PC_Case').getRecordTypeId(),
                Description = 'Test',
                Subject ='Test',
                Type = 'Cardiology',
                PC_Channel__c = 'Chat',
                PC_Specialty__c = 'Cardiology'
            );
            
            insert c;

            PC_Survey__c survey = PC_SurveyController.getSurvey(c.Id); //returns survey with no Id

            survey.PC_Was_this_session_useful__c = '5';

            insert survey;

            survey = PC_SurveyController.getSurvey(c.Id);

            system.assertEquals('5', survey.PC_Was_this_session_useful__c); 
        }
    }

    /**
    * @description Method to negatively test getSurvey method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void getSurveyTestNegative(){
        try{
            PC_Survey__c survey = PC_SurveyController.getSurvey(null);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
    }


    /**
    * @description Method to positively test saveSurvey method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void saveSurveyTestPositive(){
        User provider = [SELECT Id FROM User WHERE LastName = 'Test PC Provider' LIMIT 1];
        System.runAs(provider){
            Case c = new Case(
                RecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PC_Case').getRecordTypeId(),
                Description = 'Test',
                Subject ='Test',
                Type = 'Cardiology',
                PC_Channel__c = 'Chat',
                PC_Specialty__c = 'Cardiology'
            );
            
            insert c;

            PC_Survey__c survey = PC_SurveyController.getSurvey(c.Id); //returns survey with no Id

            survey.PC_Was_this_session_useful__c = '5';

            PC_SurveyController.saveSurvey(survey);

            survey = [SELECT PC_Was_this_session_useful__c FROM PC_Survey__c LIMIT 1];

            System.assertEquals('5', survey.PC_Was_this_session_useful__c);
        }
    }

    /**
    * @description Method to negatively test saveSurvey method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void saveSurveyTestNegative(){
        try {
            PC_SurveyController.saveSurvey(null);
            System.assert(false);
        } catch(Exception e) {
            System.assert(true);
        }
    }
    
    /**
    * @description Method to test getSurveysToComplete method
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    @isTest
    static void getSurveysToCompleteTest(){
        User provider = [SELECT Id FROM User WHERE LastName = 'Test PC Provider' LIMIT 1];
        System.runAs(provider){
            Case c = new Case(
                RecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PC_Case').getRecordTypeId(),
                Description = 'Test',
                Subject ='Test',
                Type = 'Cardiology',
                PC_Channel__c = 'Chat',
                PC_Specialty__c = 'Cardiology'
            );
            
            insert c;
            
            List<Case> lsCases = PC_SurveyController.getSurveysToComplete();
            System.assert(lsCases.size() == 1);
        }
    }
}
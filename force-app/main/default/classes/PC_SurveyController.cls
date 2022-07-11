/**
 * @description       : Class used as a controller for pcSurvey and pcSurveyList LWCs
 * @author            : George Elias
 * @group             : Booze Allen Hamilton
 * @last modified on  : 07-06-2022
 * @last modified by  : George Elias
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-06-2022   George Elias                          Initial Version
 **/
public with sharing class PC_SurveyController {

    /**
    * @description Method to get survey based on running user and case
    * @author George Elias | 07-06-2022
    * @param caseId - Case record id
    * @return  PC_Survey__c - The PC_Survey__c record associated with the ProviderConnect case
    **/
    @AuraEnabled(cacheable=true)
    public static PC_Survey__c getSurvey(Id caseId){
        try{
            Id providerRTId = Schema.SObjectType.PC_Survey__c.getRecordTypeInfosByDeveloperName().get('Provider_Survey').getRecordTypeId();
            Id specialistRTId = Schema.SObjectType.PC_Survey__c.getRecordTypeInfosByDeveloperName().get('Specialist_Survey').getRecordTypeId();
            
            Id rtId = null;
            Profile p = [SELECT Name FROM Profile WHERE Id = : UserInfo.getProfileId()];
            if (p.name.contains('Platform')){
                rtId = providerRTId;
            } else {
                rtId = specialistRTId;
            }

            List<PC_Survey__c> lsSurvey = [SELECT Id, PC_Was_this_session_useful__c, RecordTypeId FROM PC_Survey__c WHERE PC_Case__c = :caseId AND RecordTypeId = :rtId ORDER BY CreatedDate];

            PC_Survey__c returnSurvey = new PC_Survey__c(RecordTypeId = rtId, PC_Was_this_session_useful__c = '0', PC_Case__c = caseId);

            if(lsSurvey.size() > 0) {
                returnSurvey = lsSurvey[0];
            }

            return returnSurvey;
        } catch (Exception e) {
            log_LogService.log('PC_SurveyController.getSurvey Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Method to save the survey
    * @author George Elias | 07-06-2022
    * @param survey - The PC_Survey__c record to be saved
    * @return  void
    **/
    @AuraEnabled
    public static void saveSurvey(PC_Survey__c survey){
        try{
            upsert survey;
        } catch (Exception e) {
            log_LogService.log('PC_SurveyController.saveSurvey Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Method to get all cases that do not have a survey
    * @author George Elias | 07-06-2022
    * @return  List<Case> - List of Cases that do not have a completed survey
    **/
    @AuraEnabled(cacheable=true)
    public static List<Case> getSurveysToComplete(){
        try{
            return [
                SELECT Id, CaseNumber, CreatedDate, PC_Specialty__c, PC_Channel__c, Owner.Name, PC_Survey_Created__c
                FROM CASE 
                WHERE RecordType.DeveloperName = 'PC_Case'
                AND PC_Survey_Created__c excludes ('PCP Survey')
                ORDER BY CaseNumber DESC
                LIMIT 20];
        } catch (Exception e) {
            log_LogService.log('PC_SurveyController.getSurveysToComplete Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }


}

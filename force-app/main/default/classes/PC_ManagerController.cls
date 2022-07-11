/**
 * @description       : Class used as a controller for pcOmniChannelSupervisor LWC
 * @author            : George Elias
 * @group             : Booze Allen Hamilton
 * @last modified on  : 07-06-2022
 * @last modified by  : George Elias
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-06-2022   George Elias                          Initial Version
 **/
public with sharing class PC_ManagerController {

    /**
     * @description       : Wrapper class used to return data to LWC
     * @author            : George Elias
     * */
    @TestVisible
    public class AgentHistory {
        @AuraEnabled public String agentName;
        @AuraEnabled public String agentId;
        @AuraEnabled public String agentImage;
        @AuraEnabled public String currentStatus = 'Offline';
        @AuraEnabled public Decimal currentCapacity = 0;
        @AuraEnabled public List<UserServicePresence> historicStatuses = new List<UserServicePresence>();
        @AuraEnabled public List<Case> openCases = new List<Case>();
        @AuraEnabled public List<Case> allCases = new List<Case>();

    }
    
    /**
    * @description Method to fetch historical case and presence data of PC specialist
    * @author George Elias | 07-06-2022
    * @return  List<AgentHistory> - List of AgenHistory wrapper class
    **/
    @AuraEnabled
    public static List<AgentHistory> getAgentHistory(){
        try {
            List<AgentHistory> returnList = new List<AgentHistory>();
            Id pcRtId = Schema.SObjectType.ServiceResource.getRecordTypeInfosByName().get('Provider Connect Resource').getRecordTypeId();
            List<String> lsUserIds = new List<String>();
            for(ServiceResource sr : [SELECT RelatedRecordId FROM ServiceResource WHERE RecordTypeId = :pcRtId]) {
                lsUserIds.add(sr.RelatedRecordId);
            }

            Map<Id, User> mpUsers = new Map<Id, User> ([SELECT Id, Name, MediumPhotoUrl FROM User WHERE Id in :lsUserIds ORDER BY Name]);
            Map<String, List<UserServicePresence>> mpUserPresence = new Map<String, List<UserServicePresence>>();
            for(UserServicePresence usp : [
                SELECT UserId, User.Name, ServicePresenceStatus.MasterLabel, StatusStartDate, ConfiguredCapacity, 
                StatusEndDate, IsAway, IdleDuration, AtCapacityDuration, AverageCapacity, IsCurrentState, 
                StatusDuration, PC_Specialty__c, PC_Teams_Channel__c, PC_Chat_Channel__c, PC_Phone_Channel__c 
                FROM UserServicePresence
                WHERE UserId in :lsUserIds AND StatusStartDate = LAST_N_DAYS:30
                ORDER BY IsCurrentState DESC, CreatedDate DESC]) {
                if(mpUserPresence.containsKey(usp.UserId)) {
                    mpUserPresence.get(usp.UserId).add(usp);
                } else {
                    mpUserPresence.put(usp.UserId, new List<UserServicePresence>{usp});
                }
            }

            Map<String, List<Case>> mpOpenCases = new Map<String, List<Case>>();
            Map<String, List<Case>> mpAllCases = new Map<String, List<Case>>();
            for(Case c : [
                SELECT Id, CaseNumber, CreatedDate, PC_Specialty__c, PC_Channel__c, Status, OwnerId, IsClosed, ClosedDate
                FROM CASE 
                WHERE RecordType.DeveloperName = 'PC_Case' AND CreatedDate = LAST_N_DAYS:30
                ORDER BY CaseNumber DESC]) {

                if(c.IsClosed == false) {
                    if(mpOpenCases.containsKey(c.OwnerId)) {
                        mpOpenCases.get(c.OwnerId).add(c);
                    } else {
                        mpOpenCases.put(c.OwnerId, new List<Case>{c});
                    }
                }
                if(mpAllCases.containsKey(c.OwnerId)) {
                    mpAllCases.get(c.OwnerId).add(c);
                } else {
                    mpAllCases.put(c.OwnerId, new List<Case>{c});
                }
            }

            List<AgentWork> lsAW = [SELECT UserId, Status, CapacityWeight FROM AgentWork WHERE Status = 'Opened'];

            if(Test.isRunningTest()) {
                User specialist = [SELECT Id FROM User WHERE LastName = 'Test PC Manager' LIMIT 1];
    
                ServiceChannel sc = [SELECT Id FROM ServiceChannel WHERE DeveloperName = 'PC_Chat_Service' LIMIT 1];

                Case c = [SELECT Id FROM Case LIMIT 1];
                lsAW.add(new AgentWork(UserID = specialist.Id, WorkItemId =  c.Id, ServiceChannelId = sc.Id, CapacityWeight = 5));
            }

            Map<String, Decimal> mpAgentCapacity = new Map<String, Decimal>();
            for(AgentWork aw : lsAW) {
                if(mpAgentCapacity.containsKey(aw.UserId)) {
                    mpAgentCapacity.put(aw.UserId, mpAgentCapacity.get(aw.UserId) + aw.CapacityWeight);
                } else {
                    mpAgentCapacity.put(aw.UserId, aw.CapacityWeight);
                }
            }

            for(String userId : mpUsers.keySet()) {
                AgentHistory ag = new AgentHistory();
                ag.agentId = userId;
                ag.agentName = mpUsers.get(userId).Name;
                ag.agentImage = mpUsers.get(userId).MediumPhotoUrl;

                if(mpUserPresence.containsKey(userId)){
                    ag.currentStatus = mpUserPresence.get(userId)[0].IsCurrentState == true ? mpUserPresence.get(userId)[0].ServicePresenceStatus.MasterLabel.split(' - ')[0] : 'Offline';
                    ag.historicStatuses = mpUserPresence.get(userId);
                }
                if(mpAllCases.containsKey(userId)){
                    ag.allCases = mpAllCases.get(userId);
                }
                if(mpOpenCases.containsKey(userId)){
                    ag.openCases = mpOpenCases.get(userId);
                }

                if(mpAgentCapacity.containsKey(userId)){
                    ag.currentCapacity = (mpAgentCapacity.get(userId)/20) * 100;
                }
                returnList.add(ag);
            }

            return returnList;
        }  catch (Exception e) {
            log_LogService.log('PC_ManagerController.getAgentHistory Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }
}

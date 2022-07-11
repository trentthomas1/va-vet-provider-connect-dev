/**
 * @description       : Class used as a controller for multiple ProviderConnect LWCs
 * @author            : John Meyer
 * @group             : Salesforce
 * @last modified on  : 07-06-2022
 * @last modified by  : George Elias
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   10-29-2021   John Meyer                          Initial Version
 * 2.0   07-06-2022   George Elias                        Modified exisiting code to fit requirements, created new methods to extend functionality to cover new requirements
 **/
public without sharing class PC_ProviderConnectController {

    public class SkillStatus {
        @AuraEnabled public String skillName;
        @AuraEnabled public Boolean hasPresence;
        @AuraEnabled public Decimal minCapacity;
        @AuraEnabled public Boolean chatDisabled;
        @AuraEnabled public Boolean teamsDisabled;
        @AuraEnabled public Boolean phoneDisabled;
        @AuraEnabled public List<Case> openCases;
    }

    public class AvailableChannels {
        @AuraEnabled public Boolean chat;
        @AuraEnabled public Boolean teams;
        @AuraEnabled public Boolean phone;
    }

    /**
    * @description Method to fetch revelant specialities and specialist presence data
    * @author John Meyer | 10-29-2021 , George Elias | 07-06-2022
    * @param queryDate String value of JS datetime used to query for open cases created after this date
    * @return  Map<String, object> - A map containing speciailist status as 'statuses' and current users open cases as 'myCases'
    **/
    @AuraEnabled
    public static Map<String, object> getSkills (String queryDate) {
        try {
            Id pcRTId = Schema.SObjectType.ServiceResource.getRecordTypeInfosByDeveloperName().get('PC_Resource').getRecordTypeId();

            Map<Id, ServiceResourceSkill> relevantSkills = new Map<Id, ServiceResourceSkill> ([
                SELECT Skill.MasterLabel, ServiceResource.RelatedRecordId, SkillLevel
                FROM ServiceResourceSkill
                WHERE ServiceResource.ResourceType = 'A' AND ServiceResource.IsActive = true AND ServiceResource.RecordTypeId = :pcRTId
                ORDER BY Skill.MasterLabel ASC
            ]);
            

            List<UserServicePresence> presences = [
                SELECT UserId
                FROM UserServicePresence
                WHERE ServicePresenceStatus.DeveloperName = 'PC_Available_Provider_Connect'
                AND StatusStartDate >= TODAY 
                AND IsCurrentState = true
            ];
            
            List<AggregateResult> agentWorks = [
                SELECT SUM(CapacityWeight) TotalCapacity, UserId
                FROM AgentWork
                WHERE Status = 'Opened' 
                GROUP BY UserId
            ];
            
            Map<String,Boolean> skillsAndPresence = new Map<String,Boolean>();
            Map<String,Set<Id>> skillsAndUsers = new Map<String,Set<Id>>();
            Map<String,List<ServiceResource>> skillsAndSR = new Map<String, List<ServiceResource>>();
            Map<String,Set<Id>> skillsAndOnlineUsers = new Map<String,Set<Id>>();
        
            for (ServiceResourceSkill srSkill : relevantSkills.values()) {
                skillsAndUsers.put(srSkill.Skill.MasterLabel, new Set<Id>());
                skillsAndPresence.put(srSkill.Skill.MasterLabel, false);
                skillsAndSR.put(srSkill.Skill.MasterLabel, new List<ServiceResource>());
                skillsAndOnlineUsers.put(srSkill.Skill.MasterLabel, new Set<Id>());
            }

            // agentCapacity contains a list of user IDs and each one's total capacity.
            Map<Id,Decimal> agentCapacity = new Map<Id,Decimal>();
            for (AggregateResult work : agentWorks)
                agentCapacity.put((Id) work.get('UserId'), (Decimal) work.get('TotalCapacity'));

            // skillsAndUsers contains a list of skills, each with a list of users whose skill level for that skill is >= minumumSkillLevel.
            for (ServiceResourceSkill srSkill : relevantSkills.values()){
                skillsAndUsers.get(srSkill.Skill.MasterLabel).add(srSkill.ServiceResource.RelatedRecordId);
            }

            // skillsAndPresence contains a list of skills and whether or not there is a presence for each skill.
            for (UserServicePresence presence : presences)
                for (String skill : skillsAndUsers.keySet()) {
                    skillsAndPresence.put(skill, skillsAndPresence.get(skill) || skillsAndUsers.get(skill).contains(presence.UserId));
                    if(skillsAndUsers.get(skill).contains(presence.UserId))
                        skillsAndOnlineUsers.get(skill).add(presence.UserId);
                }


            Map <String, Map<String, Boolean>> skillsAndChannelPresence = getChannelPresence(skillsAndOnlineUsers, agentCapacity);

            // Send back a list of statuses for each skill that contains the maximum capacity for each skill and whether or not the
            // button for each channel should be enabled.
            List<SkillStatus> statuses = new List<SkillStatus>();
            for (String skill : skillsAndPresence.keySet()) {
                if(skill == 'Teams' || skill == 'Phone' || skill == 'Chat') {
                    continue;
                }
                SkillStatus status = new SkillStatus();
                status.skillName = skill;
                status.hasPresence = skillsAndPresence.get(skill);
                status.minCapacity = getMinCapacity(skillsAndOnlineUsers.get(skill), agentCapacity);
                Boolean checkChat = !status.hasPresence || !(status.hasPresence && skillsAndChannelPresence.get(skill).get('Chat'));
                Boolean checkTeams = !status.hasPresence || !(status.hasPresence && skillsAndChannelPresence.get(skill).get('Teams'));
                Boolean checkPhone = !status.hasPresence || !(status.hasPresence && skillsAndChannelPresence.get(skill).get('Phone'));
                if (status.minCapacity >= 20.0) {
                    status.chatDisabled = true;
                    status.teamsDisabled = true;
                    status.phoneDisabled = true;               
                } else if (status.minCapacity >= 15.0) {
                    status.chatDisabled = checkChat;
                    status.teamsDisabled = true;
                    status.phoneDisabled = true;               
                } else if (status.minCapacity > 0) {
                    status.chatDisabled = checkChat;
                    status.teamsDisabled = true;
                    status.phoneDisabled = checkPhone;  
                } else {
                    status.chatDisabled = checkChat;
                    status.teamsDisabled = checkTeams;
                    status.phoneDisabled = checkPhone;                       
                }
                statuses.add(status);
            }
            List<CaseHistory> openCases = getPCPOpenCases(DateTime.valueOfGMT(queryDate.replace('T',' ')));
            Map<String, Object> returnMap = new Map<String, Object> {'statuses' => statuses, 'myCases' => openCases};

            return returnMap;
        }  catch (Exception e) {
            log_LogService.log('PC_ProviderConnectController.getSkills Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Method to get the running user's current channel availability
    * @author George Elias | 07-06-2022
    * @return AvailableChannels - Wrapper class used to store availability for each channel
    **/
    @AuraEnabled(cacheable=true)
    public static AvailableChannels getChannelAvailability(){
        try{
            AvailableChannels ac = new AvailableChannels();
            ac.chat = false;
            ac.phone = false;
            ac.teams= false;
            List<String> lsChannelNames = new List<String> {'PC_Phone', 'PC_Teams', 'PC_Chat'};
            for(ServiceResourceSkill srs : [
                SELECT Skill.DeveloperName 
                FROM ServiceResourceSkill 
                WHERE ServiceResource.RelatedRecordId = :UserInfo.getUserId() 
                AND Skill.DeveloperName IN :lsChannelNames]){
                if(srs.Skill.DeveloperName == 'PC_Teams') {
                    ac.teams= true;
                }
                if(srs.Skill.DeveloperName == 'PC_Chat') {
                    ac.chat = true;
                }
                if(srs.Skill.DeveloperName == 'PC_Phone') {
                    ac.phone = true;
                }
            }

            return ac;
        }  catch (Exception e) {
            log_LogService.log('PC_ProviderConnectController.getChannelAvailability Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Method to set the running user's channel availability
    * @author George Elias | 07-06-2022
    * @param channel - String value of channel to change availability
    * @param value - Boolean value of new channel availability
    * @return String - String containing message for user
    **/
    @AuraEnabled
    public static String setChannelAvailability(String channel, Boolean value){
        try{
            List<UserServicePresence> presence = [
                SELECT UserId 
                FROM UserServicePresence 
                WHERE StatusStartDate >= TODAY 
                AND IsCurrentState = true 
                AND UserId = :UserInfo.getUserId()];

            if(presence.size() > 0) {
                return 'Please log out of Omni-Channel before changing channel availability.';
            }

            if(!value)   {
                List<ServiceResourceSkill> srsList = [
                    SELECT Id
                    FROM ServiceResourceSkill 
                    WHERE ServiceResource.RelatedRecordId = :UserInfo.getUserId()
                    AND Skill.MasterLabel = : channel];

                delete srsList;
            }else {
                Skill s = [SELECT Id FROM Skill WHERE MasterLabel = :channel];
                List<ServiceResourceSkill> srsList = new List<ServiceResourceSkill>();

                for(ServiceResource sr : [
                    SELECT Id
                    FROM ServiceResource
                    WHERE RelatedRecordId = :UserInfo.getUserId()]) {
                        srsList.add(new ServiceResourceSkill(SkillId = s.Id, ServiceResourceId = sr.Id, EffectiveStartDate = Date.Today(), SkillLevel = 1));
                }

                insert srsList;
            }

            return 'success';
        }  catch (Exception e) {
            log_LogService.log('PC_ProviderConnectController.setChannelAvailability Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Method to create a Provider Connect Case
    * @author John Meyer | 10-29-2021 , George Elias | 07-06-2022
    * @param skill - String containing the name of the specialty
    * @param details - String of additional case details
    * @param memberId - String of the Veteren Member ID
    * @param channel - String of the channel selected
    * @param callback - String value of the callback number
    * @return  Case - The Case record created
    **/
    @AuraEnabled 
    public static Case createCase (String skill, String details, String memberId, String channel, String callback) {
        try{
            Case c = new Case(
                RecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PC_Case').getRecordTypeId(),
                Description = details,
                Subject = channel + ' - ' + UserInfo.getName(),
                Type = skill,
                PC_Channel__c = channel,
                PC_Specialty__c = skill,
                PC_Callback_Number__c = channel == 'Phone' ? callback : null,
                PC_Veteran_Member_Id__c = memberId
            );
            
            insert c;

            return c;
        }  catch (Exception e) {
            log_LogService.log('PC_ProviderConnectController.createCase Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Method to get the assigned specialst of the case
    * @author George Elias | 07-06-2022
    * @param caseId - String value of the ProviderConnect Case
    * @return Map<String,Object> - Map containing the agent information as 'agent' and PC_Chat_Session__c record Id as 'chatId'
    **/
    @AuraEnabled
    public static Map<String,Object> getAssignedAgent(String caseId) {
        try {
            Map<String,Object> returnMap = new Map<String,String>();

            List<AgentWork> lsAW = [
                SELECT Id, UserId, User.Email, User.Name, User.MediumPhotoUrl,
                WorkItemId, WorkItem.PC_Channel__c 
                FROM Agentwork 
                WHERE WorkItemId = :caseId 
                LIMIT 1];

            //AgentWork is not being creating in test class, mocking omnichannel funtionality with Test.isRunningTest and AgentWork creation,
            //could not add online status and agent work through test class
            if(lsAW.size() > 0 || Test.isRunningTest()) {

                ////////////////Code Block for Testing//////////////
                if(Test.isRunningTest()) {
                    User specialist = [SELECT Id FROM User WHERE LastName = 'Test PC Specialist' LIMIT 1];
        
                    ServiceChannel sc = [SELECT Id FROM ServiceChannel WHERE DeveloperName = 'PC_Chat_Service' LIMIT 1];

                    lsAW.add(new AgentWork(UserID = specialist.Id, WorkItemId =  caseId, ServiceChannelId = sc.Id, CapacityWeight = 5));
                }
                ///////////////////////////////////////////////////

                //Check if same user, will throw error if share record already exist
                if(lsAW[0].UserId != UserInfo.getUserId()){
                    //Grant access to the provider. Access is removed when case is routed to agent since agent in the new owner of the record
                    CaseShare caseShare  = new CaseShare();
                    caseShare.CaseId = lsAW[0].WorkItemId;
                    caseShare.UserOrGroupId = UserInfo.getUserId();
                    caseShare.CaseAccessLevel = 'Edit';

                    insert caseShare;
                }

                String chatId = null;

                if(lsAW[0].WorkItem.PC_Channel__c == 'Chat' || Test.isRunningTest()) {
                    PC_Chat_Session__c chatSession = [SELECT Id FROM PC_Chat_Session__c WHERE PC_Case__c = :lsAW[0].WorkItemId];
                    chatId = chatSession.Id;
                    createNewChatCache(chatId);
                }

                User agent = [SELECT Id, Name, MediumPhotoUrl, Email, Street, City, State, PostalCode, Title, Department, Division FROM User WHERE Id = :lsAW[0].UserId];

                returnMap = new Map<String,Object> {
                    'agent' => agent, 
                    'chatId' => chatId};
            }
            return returnMap;
        }  catch (Exception e) {
            log_LogService.log('PC_ProviderConnectController.getAssignedAgent Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Method to cancel the specified case
    * @author George Elias | 07-06-2022
    * @param caseId - String value of the ProviderConnect Case
    * @return void
    **/    
    @AuraEnabled
    public static void cancelCase(String caseId) {
        try{
            update new Case(Id = caseId, Status='Cancelled');
        }  catch (Exception e) {
            log_LogService.log('PC_ProviderConnectController.cancelCase Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Method to cancel all open Provider Connect Cases of the running user
    * @author George Elias | 07-06-2022
    * @param cancelReason - String value of reason for closing
    * @return List<String> - List of Case record Ids that were closed
    **/    
    @AuraEnabled
    public static List<String> cancelOpenCases(String cancelReason) {
        try{
            Id pcrtid = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PC_Case').getRecordTypeId();
            List<Case> lsOpenCases = [
                SELECT Id, PC_Specialist_Comments__c 
                FROM Case 
                WHERE RecordTypeId = :pcrtid 
                AND IsClosed = false 
                AND OwnerId = :UserInfo.getUserId()];
            if(lsOpenCases.isEmpty()) {
                return new List<String>();
            }
            List<String> lsCaseIds = new List<String>();
            for(Case c : lsOpenCases) {
                c.PC_Specialist_Comments__c = String.isNotBlank(c.PC_Specialist_Comments__c)  ? c.PC_Specialist_Comments__c + '\n\nClosed Reason:\n' + cancelReason : 'Closed Reason:\n' + cancelReason;
                c.Status = 'Closed - Unresolved';
                lsCaseIds.add(c.Id);
            }
            update lsOpenCases;
            return lsCaseIds;
        }  catch (Exception e) {
            log_LogService.log('PC_ProviderConnectController.cancelOpenCases Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Decimal getMinCapacity (Set<Id> userIds, Map<Id,Decimal> agentCapacity) {
        Decimal min = 20.0;
        for (Id id : userIds){
            Decimal cap = agentCapacity.containsKey(id) ? agentCapacity.get(id) : 0 ;
            if (cap < min)
                min = cap ;
        }
        return min;

    }

    private static Map<String, Map<String, Boolean>> getChannelPresence(Map<String, Set<Id>> skillsAndUsers, Map<Id,Decimal> agentCapacity) {
        Map <String, Map<String, Boolean>> skillsAndChannelPresence = new Map <String, Map<String, Boolean>>();
        for (String skill : skillsAndUsers.keySet()) {
            skillsAndChannelPresence.put(skill, new Map<String, Boolean> {'Teams' => false, 'Chat' => false, 'Phone' => false});
            for(Id userId : skillsAndUsers.get(skill)){
                Decimal cap = agentCapacity.containsKey(userId) ? agentCapacity.get(userId) : 0 ;

                if(cap == 0 && skillsAndUsers.containsKey('Teams') && skillsAndUsers.get('Teams').contains(userId)) {
                    skillsAndChannelPresence.get(skill).put('Teams', true);
                }
                if(cap <= 15  && skillsAndUsers.containsKey('Chat') && skillsAndUsers.get('Chat').contains(userId)) {
                    skillsAndChannelPresence.get(skill).put('Chat', true);
                }
                if(cap <= 10 && skillsAndUsers.containsKey('Phone') && skillsAndUsers.get('Phone').contains(userId)) {
                    skillsAndChannelPresence.get(skill).put('Phone', true);
                }
            }
        }

        return skillsAndChannelPresence;
    }

    private static void createNewChatCache(String chatSessionId) {
        // PC_Chat_Session__c pcChatSession = new PC_Chat_Session__c(PC_Case__c = caseId);

        // insert pcChatSession;
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.pcChat');
        orgPart.put(chatSessionId, new PC_CacheResults());
        // return pcChatSession.Id;
    }

    private static List<CaseHistory> getPCPOpenCases(DateTime dt) {
        Id pcrtid = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PC_Case').getRecordTypeId();
        return [
            SELECT Id, CreatedBy.Name, CreatedDate, CaseId, Case.CaseNumber, Case.PC_Specialty__c, Case.PC_Channel__c , OldValue, NewValue 
            FROM CaseHistory 
            WHERE Field = 'Status' 
            AND CreatedDate > :dt
            AND Case.CreatedById = :UserInfo.getUserId()];
    }
}
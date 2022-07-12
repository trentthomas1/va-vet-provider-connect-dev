/**
 * @description       : Class used as a controller for pcChat LWC
 * @author            : George Elias
 * @group             : Booze Allen Hamilton
 * @last modified on  : 07-06-2022
 * @last modified by  : George Elias
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-06-2022   George Elias                          Initial Version
 **/
public with sharing class PC_ChatController {  

    /**
    * @description Method to search for the chat session and chat messages
    * @author George Elias | 07-06-2022
    * @param sessionId - Id of the PC_Chat_Session__c record
    * @param caseId - Id of the parent Case record that the PC_Chat_Session__c record is a child of
    * @param lastMessageTime - String value of datetime used to retrieve messages after this time
    * @return  PC_Chat_Session__c - The chat session record with related feed items
    **/
    @AuraEnabled 
    public static PC_Chat_Session__c getChatterMessages(String sessionId, String caseId, String lastMessageTime){

        try {
            if(String.isBlank(sessionId) && String.isBlank(caseId)) {
                throw new PC_CustomException('Session Id and Case Id cannot be both blank.');
            }
            DateTime dt = null;
            if(!String.isBlank(lastMessageTime)){
                dt = DateTime.ValueofGmt( lastMessageTime.replace('T', ' ') );
            }

            PC_Chat_Session__c session = [
                SELECT Id, CreatedBy.Name, PC_Case__C, CreatedDate, PC_Is_Closed__c, PC_Closed_Date__c, PC_Closed_By__r.Name,
                (SELECT Body, Type, ParentId, CreatedDate, InsertedBy.Name FROM feeds WHERE type ='TextPost' and CreatedDate > :dt ORDER BY CreatedDate)
                FROM PC_Chat_Session__c 
                WHERE Id = :sessionId OR PC_Case__c = :caseId
                LIMIT 1];
            return session;
        } catch (Exception e) {
            log_LogService.log('PC_ChatController.getChatterMessages Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }

 
    /**
    * @description Method to search for the chat session and chat messages in cache
    * @author George Elias | 07-06-2022
    * @param sessionId - Id of the PC_Chat_Session__c record
    * @param lastMessageTime - String value of datetime used to retrieve messages after this time
    * @return  PC_CacheResults - Chat session details and messages in a wrapper class
    **/
    @AuraEnabled
    public static PC_CacheResults getChatterMessagesCache(String sessionId, String lastMessageTime){
        try { 
            if(String.isBlank(sessionId)) {
                throw new PC_CustomException('Session Id cannot be blank.');
            }
            DateTime dt = null;
            if(!String.isBlank(lastMessageTime)){
                dt = DateTime.ValueofGmt( lastMessageTime.replace('T', ' ') );
            }
            Cache.OrgPartition orgPart = Cache.Org.getPartition('local.pcChat');
            PC_CacheResults cacheResults = new PC_CacheResults();
            //Check if cache exists
            if(orgPart.contains(sessionId)) {
                //if exists, use cache
                cacheResults = (PC_CacheResults) orgPart.get(sessionId);
                List<FeedItem> tempList = new List<FeedItem>();
                for(FeedItem chat : cacheResults.chatList) {
                    if(chat.CreatedDate > dt || dt == null){
                        tempList.add(chat);
                    }
                }
                cacheResults.chatList = tempList;
            } else {
                //if not query data bases
                PC_Chat_Session__c session = [
                SELECT PC_Is_Closed__c, PC_Closed_Date__c, PC_Closed_By__r.Name
                FROM PC_Chat_Session__c 
                WHERE Id = :sessionId
                LIMIT 1];

                cacheResults.isClosed = session.PC_Is_Closed__c;
                cacheResults.closedBy = session.PC_Closed_By__r?.Name;
                cacheResults.closedDate = session.PC_Closed_Date__c;
                cacheResults.chatList = [
                    SELECT Body, Type, ParentId, CreatedDate, InsertedBy.Name 
                    FROM FeedItem 
                    WHERE ParentId = :sessionId 
                    AND type ='TextPost' and CreatedDate > :dt 
                    ORDER BY CreatedDate];
            }
            return cacheResults;
        }catch (Exception e) {
            log_LogService.log('PC_ChatController.getChatterMessagesCache Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Method to a chat message to chatter
    * @author George Elias | 07-06-2022
    * @param sessionId - Id of the PC_Chat_Session__c record
    * @param message - String value the chat message
    * @return  void
    **/
    @AuraEnabled
    public static void saveChatterMessage(String sessionId, String message){
        try{
            if(String.isBlank(sessionId)) {
                throw new PC_CustomException('Session Id cannot be blank.');
            } else if(String.isBlank(message)) {
                throw new PC_CustomException('Message cannot be blank.');
            }
            //Used to maintain a maximum list size for chatList
            Integer CACHE_MAX_LIST_SIZE = 20;


            FeedItem chat = new FeedItem(ParentId=sessionId, Type='TextPost', Body=message, IsRichText = false, NetworkScope='AllNetworks', Visibility='InternalUsers', Status='Published');
            insert chat;

            //Update PC_Last_Chat_Date__c which is then used in a flow to auto close a session 20 minutes after the last chat
            update new PC_Chat_Session__c(Id = sessionId, PC_Last_Chat_Date__c = System.now());

            //
            chat = [SELECT Body, Type, ParentId, CreatedDate, InsertedBy.Name FROM FeedItem WHERE Id = :chat.Id];
            //Check if cache exists
            Cache.OrgPartition orgPart = Cache.Org.getPartition('local.pcChat');
            PC_CacheResults cacheResult = new PC_CacheResults();
            if(orgPart.contains(sessionId)) {
                //add to existing cache
                cacheResult = (PC_CacheResults) orgPart.get(sessionId);
                cacheResult.chatList.add(chat);
                if(cacheResult.chatList.size() > CACHE_MAX_LIST_SIZE) {
                    cacheResult.chatList.remove(0);
                }
            } else {
                //create new cache and add chat to new cache
                PC_Chat_Session__c session = [
                SELECT PC_Is_Closed__c, PC_Closed_Date__c, PC_Closed_By__r.Name
                FROM PC_Chat_Session__c 
                WHERE Id = :sessionId
                LIMIT 1];
                
                cacheResult.isClosed = session.PC_Is_Closed__c;
                cacheResult.closedBy = session.PC_Closed_By__r?.Name;
                cacheResult.closedDate = session.PC_Closed_Date__c;
                cacheResult.chatList.add(chat);
            }

            orgPart.put(sessionId, cacheResult);
        }catch (Exception e) {
            log_LogService.log('PC_ChatController.saveChatterMessage Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
    * @description Method to close the chat session
    * @author George Elias | 07-06-2022
    * @param sessionId - Id of the PC_Chat_Session__c record
    * @return  PC_Chat_Session__c - The closed PC_Chat_Session__c record
    **/
    @AuraEnabled
    public static PC_Chat_Session__c closeChatSession(String sessionId){
        try {
            if(String.isBlank(sessionId)) {
                throw new PC_CustomException('Session Id cannot be blank.');
            }
            PC_Chat_Session__c session = [SELECT PC_Is_Closed__c FROM PC_Chat_Session__c WHERE Id = : sessionId];
            if(session.PC_Is_Closed__c == false){
                update new PC_Chat_Session__c(
                    Id = sessionId, 
                    PC_Is_Closed__c = true, 
                    PC_Closed_Date__c = Datetime.now(), 
                    PC_Closed_By__c = UserInfo.getUserId());
            }

            return [
                SELECT Id, CreatedBy.Name, PC_Case__C, CreatedDate, PC_Is_Closed__c, PC_Closed_Date__c, PC_Closed_By__r.Name
                FROM PC_Chat_Session__c 
                WHERE Id = :sessionId
                LIMIT 1];
        } catch(Exception e) {
            log_LogService.log('PC_ChatController.closeChatSession Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }
}
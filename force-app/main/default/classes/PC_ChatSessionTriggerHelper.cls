/**
 * @description       : Helper class for the PC_Chat_Session__c Trigger
 * @author            : George Elias
 * @group             : Booze Allen Hamilton
 * @last modified on  : 07-06-2022
 * @last modified by  : George Elias
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-06-2022   George Elias                          Initial Version
 **/
public with sharing class PC_ChatSessionTriggerHelper {
    
    /**
    * @description Method to clear chat session data from cache
    * @author George Elias | 07-06-2022
    * @param lsSession - List of PC_Chat_Session__c records
    * @return  void
    **/
    public static void clearSessionCacheData(List<PC_Chat_Session__c> lsSessions){
        try{
            Cache.OrgPartition orgPart = Cache.Org.getPartition('local.pcChat');
            for(PC_Chat_Session__c session : lsSessions) {
                if(orgPart.contains(session.Id) && session.PC_Is_Closed__c){
                    orgPart.remove(session.Id);
                }
            }
        } catch (Exception e) {
            log_LogService.log('PC_ChatSessionTriggerHelper.clearSessionCacheData Exception', log_LogService.LogType.ERROR, e);
            log_LogService.publish();
            throw new AuraHandledException(e.getMessage());
        }
    }
}

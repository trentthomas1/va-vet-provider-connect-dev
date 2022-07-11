trigger PC_ChatSessionTrigger on PC_Chat_Session__c (after insert, after update) {
    Boolean hasPermission = FeatureManagement.checkPermission('DisableTriggersFlag');
    if(!hasPermission) {
        PC_ChatSessionTriggerHelper.clearSessionCacheData(Trigger.new);
    }
}
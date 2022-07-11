/**
 * @description       : Class used as a wrapper class to save chat details to cache
 * @author            : George Elias
 * @group             : Booze Allen Hamilton
 * @last modified on  : 07-06-2022
 * @last modified by  : George Elias
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-06-2022   George Elias                          Initial Version
 **/
public class PC_CacheResults {
    @AuraEnabled public String closedBy = null;
    @AuraEnabled public DateTime closedDate = null;
    @AuraEnabled public Boolean isClosed = false;
    @AuraEnabled public List<FeedItem> chatList = new List<FeedItem>();
}

/**
 * @description       : Class used as a help for PC_ChatController, used to get around 'Implementation restriction: FeedItem requires a filter by Id' error
 * @author            : George Elias
 * @group             : Booze Allen Hamilton
 * @last modified on  : 08-16-2022
 * @last modified by  : George Elias
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   8-16-2022   George Elias                          Initial Version
 **/
public without sharing class PC_ChatControllerHelper {
    
    /**
    * @description Method to query feeditem
    * @author George Elias | 08-16-2022
    * @param sessionId - Id of the PC_Chat_Session__c record
    * @param dt - Datetime used to retrieve messages after this time
    * @return  List<FeedItem>
    **/
    public static List<FeedItem> queryFeedItem(String sessionId, DateTime dt) {
        return [SELECT Body, Type, ParentId, CreatedDate, InsertedBy.Name 
            FROM FeedItem 
            WHERE ParentId = :sessionId 
            AND type ='TextPost' and CreatedDate > :dt  //Cannot use security enforced with InsertedBy field, Apex Class is secured with permission set for PC users only
            ORDER BY CreatedDate];
        }
}

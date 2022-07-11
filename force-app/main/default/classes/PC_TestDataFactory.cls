/**
 * @description       : Utility class used to assist with provider connect test data creation
 * @author            : George Elias
 * @group             : Booze Allen Hamilton
 * @last modified on  : 07-06-2022
 * @last modified by  : George Elias
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-06-2022   George Elias                          Initial Version
 **/
@isTest
public class PC_TestDataFactory {

    /**
    * @description Method to create a specialist user
    * @author George Elias | 07-06-2022
    * @param lastName - Last name of new user
    * @return  User - new user created
    **/
    public static User createSpecialist(String lastName) {
        final Profile base = [SELECT Id FROM Profile WHERE Name = 'VAVET Base Profile'];

        final User pcSpecialist = UnitTestHelper.createTestUser(null, base.Id, 'test', lastName);
        insert pcSpecialist;

        PermissionSetGroup psg = [SELECT Id FROM PermissionSetGroup where masterlabel='PC Specialist'];

        mockPermGroupAssignment(pcSpecialist.Id, psg.Id);

        return pcSpecialist;
    }

    /**
    * @description Method to create a provider user
    * @author George Elias | 07-06-2022
    * @param lastName - Last name of new user
    * @return  User - new user created
    **/
    public static User createProvider(String lastName) {
        final Profile base = [SELECT Id FROM Profile WHERE Name = 'VAVET Base Platform'];

        final User pcProvider = UnitTestHelper.createTestUser(null, base.Id, 'test', lastName);
       
        insert pcProvider;

        PermissionSetGroup psg = [SELECT Id FROM PermissionSetGroup where masterlabel='PC Primary Care Physician'];

        mockPermGroupAssignment(pcProvider.Id, psg.Id);

        return pcProvider;
    }

    /**
    * @description Method to create a manager user
    * @author George Elias | 07-06-2022
    * @param lastName - Last name of new user
    * @return  User - new user created
    **/
    public static User createManager(String lastName) {
        final Profile base = [SELECT Id FROM Profile WHERE Name = 'VAVET Base Profile'];

        final User pcManager = UnitTestHelper.createTestUser(null, base.Id, 'test', lastName);

        insert pcManager;

        PermissionSetGroup psg = [SELECT Id FROM PermissionSetGroup where masterlabel='PC Specialist Manager'];

        mockPermGroupAssignment(pcManager.Id, psg.Id);

        return pcManager;
    }

    /**
    * @description Method to create a service resource record and add skills
    * @author George Elias | 07-06-2022
    * @param pcUserId - Id of user
    * @param name - Name of new ServiceResource record
    * @param skillName - Name of Specialty to assign
    * @return  ServiceResource - new ServiceResource record created
    **/
    public static ServiceResource createServiceResource(Id pcUserId, String name, String skillName) {
        ServiceResource objServiceResource=new ServiceResource();
        objServiceResource.Name = name;
        objServiceResource.RelatedRecordId = pcUserId;
        objServiceResource.ResourceType = 'A';
        objServiceResource.IsActive = true;
        objServiceResource.PC_Assigned_Specialty__c = skillName;
        objServiceResource.RecordTypeId = ServiceResource.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PC_Resource').getRecordTypeId();
        insert objServiceResource; 
        
        return objServiceResource;
    }

    /**
    * @description Method to create a service resource skill record, used to create available channels
    * @author George Elias | 07-06-2022
    * @param srId - ServiceResource record Id
    * @param skillId - Skill record Id
    * @return  ServiceResourceSkill - new ServiceResourceSkill created
    **/
    public static ServiceResourceSkill createServiceResourceSkill(Id srId, Id skillId) {
        ServiceResourceSkill objServiceResourceSkill = new ServiceResourceSkill();
        objServiceResourceSkill.ServiceResourceId=srId;
        objServiceResourceSkill.SkillId = skillId;
        objServiceResourceSkill.EffectiveStartDate=System.today();
        insert objServiceResourceSkill;

        return objServiceResourceSkill;
    }

    /**
    * @description Method to mimic permission set group assignments
    * @author George Elias | 07-06-2022
    * @return  void
    **/
    public static void mockPermGroupAssignment(Id userId, Id psgId) {
        List<PermissionSetAssignment> lsPSA = new List<PermissionSetAssignment>();

        for(PermissionSetGroupComponent psgc: [SELECT PermissionSetId FROM PermissionSetGroupComponent WHERE PermissionSetGroupId = :psgId]) {
            lsPSA.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = psgc.PermissionSetId));
        }

        insert lsPSA;
    }

    /**
    * @description Method to mimic criteria sharing for case
    * @author George Elias | 07-06-2022
    * @param caseList - List of cases to share
    * @param userId - Id of the user to share records with
    * @return  void
    **/
    public static void mockCaseCriteriaSharing(List<Case> caseList, Id userId) {
        final List<CaseShare> caseShareList = new List<CaseShare>();

        for(Case c : caseList) {

            if(c.CreatedById == userId) {
                continue;
            }

            final CaseShare caseShare  = new CaseShare();
        
            caseShare.CaseId = c.Id;
                
            caseShare.UserOrGroupId = userId;
                
            caseShare.CaseAccessLevel = 'Edit';
                
            caseShare.RowCause = Schema.CaseShare.RowCause.Manual;

            caseShareList.add(caseShare);
        }

        insert caseShareList;
    }


    /**
    * @description Method to mimic criteria sharing for ServiceResource
    * @author George Elias | 07-06-2022
    * @param srList - List of service resources to share
    * @param userId - Id of the user to share records with
    * @return  void
    **/
    public static void mockResourceCriteriaSharing(List<ServiceResource> srList, Id userId) {
        final List<ServiceResourceShare> srShareList = new List<ServiceResourceShare>();

        for(ServiceResource sr : srList) {

            if(sr.CreatedById == userId) {
                continue;
            }

            final ServiceResourceShare srShare  = new ServiceResourceShare();
        
            srShare.ParentId = sr.Id;
                
            srShare.UserOrGroupId = userId;
                
            srShare.AccessLevel = 'Edit';
                
            srShare.RowCause = Schema.ServiceResourceShare.RowCause.Manual;

            srShareList.add(srShare);
        }

        insert srShareList;
    }
}

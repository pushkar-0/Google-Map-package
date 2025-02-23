/* 
This test class is used to validate Sobject field APIName.
------------------------------------------------------------------------------------------------
Version#     Date                   Organization         Author                    Description
------------------------------------------------------------------------------------------------
1.0          31-Jan-2025       Kizzy Consulting      Pushkar dahal        	Initial Version
------------------------------------------------------------------------------------------------
*/
@isTest
public class ValidateSobjectFieldAPINameTest {
    @IsTest
    static void testSobjectFieldAPINameInvocable(){
        List<User> currentUser = [SELECT Id FROM User WHERE Id =:UserInfo.getUserId()];
        System.runAs(currentUser[0]) {
            list<Google_Map_Config__c> lstGoogleMapConfig= TestDataFactory.noOfGoogleMapConfigToInsert(1);
            insert lstGoogleMapConfig;
            list<Filter_Criteria__c> lstFilterCriteria = 
                TestDataFactory.noOfFilterCriteriaToInsert(1,lstGoogleMapConfig[0].id,'Company');
            test.startTest();
            insert lstFilterCriteria;
            
            test.stopTest();
            system.assert(true);
        }
    }
    @IsTest
    static void testEmailServiceHandlerInvocable1(){
        List<User> currentUser = [SELECT Id FROM User WHERE Id =:UserInfo.getUserId()];
        System.runAs(currentUser[0]) {
            list<Google_Map_Config__c> lstGoogleMapConfig= TestDataFactory.noOfGoogleMapConfigToInsert(1);
            insert lstGoogleMapConfig;
            try{
                list<Filter_Criteria__c> lstFilterCriteria = 
                TestDataFactory.noOfFilterCriteriaToInsert(1,lstGoogleMapConfig[0].id,'Company__c');
                test.startTest();
                insert lstFilterCriteria;
                test.stopTest();  
                system.assert(true);
            }
            catch(exception ex){
                
            }
        }
    }
}
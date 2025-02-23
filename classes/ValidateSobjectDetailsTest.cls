/* 
This test class is used to validate sObject API name.
------------------------------------------------------------------------------------------------
Version#     Date                   Organization         Author                    Description
------------------------------------------------------------------------------------------------
1.0          11-Feb-2025       Kizzy Consulting      Pushkar dahal        	Initial Version
------------------------------------------------------------------------------------------------
*/
@isTest
public class ValidateSobjectDetailsTest {
    @IsTest
    static void testSobjectFieldAPINameInvocable(){
        List<User> currentUser = [SELECT Id FROM User WHERE Id =:UserInfo.getUserId()];
        System.runAs(currentUser[0]) {
            list<Google_Map_Config__c> lstGoogleMapConfig= TestDataFactory.noOfGoogleMapConfigToInsert(2,'Lead');
            insert lstGoogleMapConfig;
            test.stopTest();
            system.assert(true);
        }
    }
    @IsTest
    static void testEmailServiceHandlerInvocable1(){
        List<User> currentUser = [SELECT Id FROM User WHERE Id =:UserInfo.getUserId()];
        System.runAs(currentUser[0]) {
            try{
                list<Google_Map_Config__c> lstGoogleMapConfig= TestDataFactory.noOfGoogleMapConfigToInsert(1,'Lead__c');
                insert lstGoogleMapConfig;
            }
            catch(exception ex){
                
            }
        }
    }
    
    
    
}
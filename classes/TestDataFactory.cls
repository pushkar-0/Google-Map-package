public with sharing class TestDataFactory {
    public static list<Account> noOfAccountToInsert (integer noOfRecord , string company ){
        list<Account> lstAccount= new list<Account>();
        for(integer i=0;i<noOfRecord;i++){
            Account newAccount = new Account();
            newAccount.Name = company;
            //newAccount.Client_Type__c = 'Equipment Seller'; /*Removed by Nikhil on 21-01-2024*/
            lstAccount.add (newAccount);
        }
        return lstAccount;
    }
     public static list<Google_Map_Config__c> noOfGoogleMapConfigToInsert (integer noOfRecord,string objectName ){
        list<Google_Map_Config__c> lstGoogleMapConfig= new list<Google_Map_Config__c>();
        for(integer i=0;i<noOfRecord;i++){
            Google_Map_Config__c newGoogleMapConfig = new Google_Map_Config__c();
            newGoogleMapConfig.Object_Name__c = objectName;
            newGoogleMapConfig.IsActive__c = true;                
            lstGoogleMapConfig.add (newGoogleMapConfig);
        }
        return lstGoogleMapConfig;
    }
    
    public static list<Filter_Criteria__c> noOfFilterCriteriaToInsert (integer noOfRecord,string googleMapConfigId ,string fieldName){
        list<Filter_Criteria__c> lstFilterCriteria= new list<Filter_Criteria__c>();
        for(integer i=0;i<noOfRecord;i++){
            Filter_Criteria__c newFilterCriteria = new Filter_Criteria__c();
            newFilterCriteria.Field_Name__c = fieldName;
            newFilterCriteria.IsActive__c = true;     
            newFilterCriteria.Google_Map_Config__c = googleMapConfigId;
            lstFilterCriteria.add (newFilterCriteria);
        }
        return lstFilterCriteria;
    }
    
    
}
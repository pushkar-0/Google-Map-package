/* 
This class is used to display details on Google Map component.
------------------------------------------------------------------------------------------------
Version#     Date                   Organization         Author                    Description
------------------------------------------------------------------------------------------------
1.0          23-Jan-2025       Kizzy Consulting      Pushkar Dahal        	Initial Version
------------------------------------------------------------------------------------------------
*/ 
public class SobjectGoogleMapController {
    /*
* @author 		: Pushkar Dahal
* @date   		: 23-Jan-2025
* @description 	: This method is used to get field data that we have to use it in Filter screen.
* @param 		: None
*/
    @AuraEnabled
    public static AuraResponse getGoogleMapFilterDdata(){
        AuraResponse auraResponse;
        Integer Value = 0;
        try{
            list<objectDetails> lstobjectDetails = new list<objectDetails>();
            list<Google_Map_Config__c> lstGoogleMapConfig = [SELECT Id, OwnerId, Name, 
                                                             CreatedDate, Object_Name__c, IsActive__c,
                                                             (SELECT Id, OwnerId, Name, Field_Name__c, 
                                                              Google_Map_Config__c, IsActive__c 
                                                              FROM Filter_Criteria__r WHERE IsActive__c = True)
                                                             FROM Google_Map_Config__c 
                                                             WHERE IsActive__c = True];
             
            if(lstGoogleMapConfig != null && !lstGoogleMapConfig.isEmpty()){
                for(Google_Map_Config__c eachGoogleMapConfig : lstGoogleMapConfig){
                   
                    List<FieldDetails> lstFieldDetails = new List<FieldDetails>();
                    for(Filter_Criteria__c eachFilterCriteria : eachGoogleMapConfig.Filter_Criteria__r){
                        List<PicklistOptions> lstPicklistOptions = new List<PicklistOptions>();
                        if(string.IsNotBlank(eachGoogleMapConfig.Object_Name__c) && string.IsNotBlank(eachFilterCriteria.Field_Name__c)){
                            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(eachGoogleMapConfig.Object_Name__c);
                            // Get the map of all fields for the SObject
                            Map<String, Schema.SObjectField> fieldMap;
                            if(sObjectType != null){
                                fieldMap = sObjectType.getDescribe().fields.getMap();
                            }
                            // Retrieve the field description for the specific field
                            if (fieldMap.containsKey(eachFilterCriteria.Field_Name__c)) {
                                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(eachFilterCriteria.Field_Name__c).getDescribe();
                                // Get the field data type
                                Schema.DisplayType fieldType = fieldDescribe.getType();
                                if(String.Valueof(fieldType) == 'PICKLIST'){
                                    List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
                                    System.debug('Picklist values for field ' + eachFilterCriteria.Field_Name__c + ':');
                                    for (Schema.PicklistEntry eachPicklist : picklistValues) {
                                        lstPicklistOptions.add(new PicklistOptions(eachPicklist.getLabel(),eachPicklist.getValue()));
                                        System.debug(eachPicklist.getLabel() + ' (' + eachPicklist.getValue() + ')');
                                    }
                                    lstFieldDetails.add(new FieldDetails(eachFilterCriteria.Field_Name__c,String.Valueof(fieldType),null,lstPicklistOptions));
                                }
                                else{
                                    lstFieldDetails.add(new FieldDetails(eachFilterCriteria.Field_Name__c,String.Valueof(fieldType),null,null));
                                }
                                // Output the field data type
                                System.debug('Field Type for ' + eachGoogleMapConfig.Object_Name__c + ' ' + eachFilterCriteria.Field_Name__c + ': ' + fieldType);
                            } else {
                                System.debug('Field ' + eachFilterCriteria.Field_Name__c + ' not found on object ' + eachGoogleMapConfig.Object_Name__c);
                            }
                        }
                        system.debug('value::'+value);
                    }
                    lstobjectDetails.add(new objectDetails(eachGoogleMapConfig.Object_Name__c,lstFieldDetails,Value++));
                }
            }
            
            if(lstobjectDetails != null && !lstobjectDetails.isEmpty()){
                
                auraResponse  = new auraResponse(True,'Success',JSON.serialize(lstobjectDetails));
                system.debug('auraResponse:'+JSON.serialize(auraResponse));
                return auraResponse;
            }
        }
        catch(exception ex){
            return auraResponse  = new auraResponse(False,'Error',JSON.serialize(ex.getMessage()));
        }
        return null;
    }
    /*
* @author 		: Pushkar Dahal
* @date   		: 23-Jan-2025
* @description	: Class used to send response information back to LWC. 
* 				  This class encapsulates the success status, message, and response data 
* 				  that will be sent back to the LWC component after processing.
*/    
    public class AuraResponse{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public string message;
        @AuraEnabled public string response;
        
        AuraResponse(Boolean isSuccess,String message,string response){
            this.isSuccess = isSuccess;
            this.message = message;
            this.response = response;
        }
    }
    
    public class objectDetails{
        @AuraEnabled public string ObjectName;
        @AuraEnabled public list<FieldDetails> lstFieldDetails;
        @AuraEnabled public Integer Order;
        objectDetails(String ObjectName,list<FieldDetails> lstFieldDetails,Integer Order){
            this.ObjectName = ObjectName;
            this.lstFieldDetails = lstFieldDetails;
            this.Order = Order;
        } 
    }
    
    public class FieldDetails{
        @AuraEnabled public string fieldAPIName;
        @AuraEnabled public string dataType;
        @AuraEnabled public string selectedValues;
        @AuraEnabled public list<PicklistOptions> lstPicklistOptions;
        
        FieldDetails(String fieldAPIName, String dataType,string selectedValues,list<PicklistOptions> lstPicklistOptions){
            this.fieldAPIName = fieldAPIName;
            this.dataType = dataType;
            this.selectedValues = selectedValues;
            this.lstPicklistOptions = lstPicklistOptions;
        } 
    }
    
    public class PicklistOptions{
        @AuraEnabled public string label;
        @AuraEnabled public string value;
        
        PicklistOptions(String label,string value){
            this.label = label;
            this.value = value;
        } 
    }
    /*
* @author 		: Pushkar dahal
* @date   		: 27-jan-2025
* @description 	: This class defines the properties for a single sobject Addresses record. 
* 				  
*/    
        public class AddressWrapper{
            @AuraEnabled public String Street;
            @AuraEnabled public String City;
            @AuraEnabled public String State;
            @AuraEnabled public String Country;
            @AuraEnabled public String PostalCode;
            @AuraEnabled public Decimal Longitude;
            @AuraEnabled public Decimal Latitude;
            
            
            AddressWrapper(){}
            
            AddressWrapper(	String street,
                            String city,
                            String State,
                            String country,
                            String PostalCode,
                          Decimal Longitude,
                          Decimal Latitude){
                this.street = street;
                this.city = city;
                this.State = State;
                this.country = country;
                this.PostalCode = PostalCode;
                this.Longitude = Longitude;
                this.Latitude = Latitude; 
            }
        }    
    
    
}
/* 
This class is used to display details on Google Map component.
------------------------------------------------------------------------------------------------
Version#     Date                   Organization         Author                    Description
------------------------------------------------------------------------------------------------
1.0          22-Jan-2025       Kizzy Consulting      Pushkar dahal        	Initial Version
------------------------------------------------------------------------------------------------
*/ 
public class SobjectKizzyMapController {
    /*
* @author 		: Pushkar Dahal
* @date   		: 23-Jan-2025
* @description 	: This method is used to get field data that we have to use it in Filter screen.
* @param 		: None
*/
    @AuraEnabled
    public static AuraResponse getKizzyMapFilterDdata(){
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
* @author 		: Pushkar dahal
* @date   		: 22-Jan-2025
* @description 	: This method is used to get the Agent's longitude and Latitude coordinates using the address from the filter screen
* @param 		: address from the filter screen
*/
    @AuraEnabled
    public static AuraResponse getAgentCoordinates(String address, String radius){
        AuraResponse AuraResponse;
        system.debug('address::'+address);
        try{
            String EndPointUrl;
            String HttpMethod;
            list<API_Configurations__mdt> lstAPIConfiguration = [SELECT MasterLabel, 
                                                                 Endpoint_URL__c, 
                                                                 HTTP_Method__c, 
                                                                 isActive__c 
                                                                 FROM API_Configurations__mdt 
                                                                 WHERE isActive__c = true 
                                                                 AND DeveloperName = 'Fetch_Coordinates_Nominatim' LIMIT 1];
            
            if(lstAPIConfiguration != Null && !lstAPIConfiguration.isEmpty()){
                if(lstAPIConfiguration[0].Endpoint_URL__c != Null && lstAPIConfiguration[0].HTTP_Method__c != Null){
                    EndPointUrl = lstAPIConfiguration[0].Endpoint_URL__c;
                    HttpMethod =  lstAPIConfiguration[0].HTTP_Method__c;
                }
            }
            AddressWrapper newAddress;
            String apiUrl;
            string country;
            String agentAddress;
            
            If(string.isNotBlank(address)){
                newAddress = (AddressWrapper) JSON.deserialize(address, AddressWrapper.class);
                agentAddress = '{"'+newAddress.sobjectStreet+'","'+newAddress.sobjectCity+'","'+newAddress.sobjectState+'","'+newAddress.sobjectPostalCode+'"}';
                system.debug('*** agentAddress *** ' + agentAddress);
                If(EndPointUrl != Null && String.isNotBlank(EndPointUrl)){
                    apiUrl = EndPointUrl + EncodingUtil.urlEncode(agentAddress, 'UTF-8') + '&format=json';
                }else{
                    system.debug('EndPointUrl Method is not present');
                }
                
                system.debug('*** apiUrl *** ' + apiUrl);
            }
            HttpRequest request;
            if(HttpMethod != Null && String.isNotBlank(HttpMethod)){
                request = prepareRequest(apiUrl,HttpMethod,60000);
            }else{
                system.debug('HTTP Method is not present');
            }
            
            system.debug('request:::'+request);
            Http http = new Http();
            HttpResponse response = http.send(request);
            system.debug('response::'+response);
            // Successful request
            if (response.getStatusCode() == 200) {
                Map<String, Object> mapOfStringVsObject;
                system.debug('*** Request Success ***');
                
                List<Object> lstResults = (List<Object>) JSON.deserializeUntyped(response.getBody());
                system.debug('*** lstResults *** ' + lstResults);
                
                if (lstResults!= Null && lstResults.size() > 0) {
                    system.debug('lstResults.size() > 0');
                    If(lstResults[0] != Null){
                        mapOfStringVsObject = (Map<String, Object>) lstResults[0];
                        system.debug('*** mapOfStringVsObject ***'+mapOfStringVsObject);
                    }
                    
                    // Checks for Longitude/Latitude in the map
                    if(mapOfStringVsObject != null 
                       && !mapOfStringVsObject.isEmpty() 
                       && mapOfStringVsObject.containsKey('lat') 
                       && mapOfStringVsObject.get('lat') != null 
                       && mapOfStringVsObject.containsKey('lon') 
                       && mapOfStringVsObject.get('lon') != null)
                    {
                        system.debug('Map contains Long/Lat');
                        String lon = String.valueOf(mapOfStringVsObject.get('lon')) ?? '';
                        String lat = String.valueOf(mapOfStringVsObject.get('lat')) ?? '';
                        AuraResponse = new AuraResponse(true ,'Success',JSON.serialize(new Geolocation(lon,lat)));
                        return AuraResponse;
                        
                    }// Longitude/Latitude not found in the map
                    else{
                        system.debug('Inside Else for long/lat');
                        return  AuraResponse = new AuraResponse(false ,'Error !!' ,'Agent\'s Longitude/Latitude not found by API !! ');  
                    }                    
                } 
                else {
                    system.debug('lstResults.size() < 0');
                    return  AuraResponse = new AuraResponse(false ,'Error !!','Agent\'s Longitude/Latitude not found by API !!');  
                }
            } 
            else {	// Request Failed
                system.debug('*** Request Failed ***'+response.getStatus());
                AuraResponse = new AuraResponse(false ,'API request Failed for fetching the Longitude/Latitude.',response.getStatus());  
                return AuraResponse;
            }
        }
        catch(exception ex){
            system.debug('*** Inside Catch ***');
            System.debug('Error Message: ' + ex.getMessage());
            System.debug('Line Number: ' + ex.getLineNumber());
            System.debug('Exception Type: ' + ex.getTypeName());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
            return AuraResponse = new AuraResponse(false ,'Error',ex.getmessage());
        }
    }    
    
    /*
* @author 		: Pushkar Dahal
* @date   		: 22-Jan-2025
* @description 	: This method is used to get the sObject address details based on sobjectid
* @param 		:  from the filter screen
*/    
    @AuraEnabled
    public static AuraResponse getsObjectAddress(string sobjectId,string fieldName){
        system.debug('sobjectId::'+sobjectId+'fieldName::'+fieldName);
        
        AuraResponse auraResponse;
        try{
            Id sobjectIdForName = (Id) sobjectId;
            SObjectType sObjectType = sobjectIdForName.getSObjectType();
            String objectApiName = sObjectType.getDescribe().getName();
            system.debug('objectApiName::'+objectApiName);
            list<SObject> lstSobject = new list<SObject>();
            AddressWrapper newAddressWrapper = new AddressWrapper();
            if(string.IsNotBlank(sobjectId)){
                String query = 'SELECT Id,' + fieldName + ' FROM ' + objectApiName + ' WHERE Id = \'' + sobjectId + '\'';
                system.debug('query::'+query);
                lstSobject = Database.query(query);
            }
            
            if(lstSobject != null && !lstSobject.isEmpty()){
                for(SObject eachSObject : lstSobject) {
                    newAddressWrapper.Address = JSON.serialize(eachSObject.get(fieldName)); 
                }
            }
            system.debug('newAddressWrapper::'+newAddressWrapper);
            return AuraResponse = new AuraResponse(true ,'Success',JSON.serialize(newAddressWrapper)); 
        }
        catch(exception ex){
            return AuraResponse = new AuraResponse(false ,'Error',ex.getmessage());
        }        
    }  
    
    /*
* @author 		: Pushkar dahal
* @date   		: 22-Jan-2025
* @description 	: This method is used to get the sObject within specified radius
* @param 		: longitude, latitude and radius from the parent LWC
*/
    @AuraEnabled
    public static AuraResponse getNearbysObject(String radius,string sObjectName,string fieldAPIName,string sObjectData){
        
        AuraResponse AuraResponse;
        try{
            list<objectDetails> lstobjectDetails = 
                (list<objectDetails>) JSON.deserialize(sObjectData, List<objectDetails>.class);
            system.debug('lstobjectDetails::'+lstobjectDetails);
            
            decimal longitude;
            decimal latitude;
            string soqlcondition='';
            String sobjectfieldNameToDisplay = 'Id,';
            Set<String> stringSet = new Set<String>();
            if(lstobjectDetails != null && !lstobjectDetails.isEmpty()){
                for (objectDetails obj : lstobjectDetails) {
                    if (obj.ObjectName == sObjectName) {
                        for (FieldDetails field : obj.lstFieldDetails) {
                            system.debug('field::'+field.fieldAPIName+'  field.selectedValues::  '+field.selectedValues);
                            system.debug('compare:'+ field.fieldAPIName != fieldAPIName);
                            if(field.selectedValues != null &&
                               field.fieldAPIName != null &&
                               field.fieldAPIName != fieldAPIName){
                                   system.debug('enter in field::');
                                   //sobjectfieldNameToDisplay += field.fieldAPIName + ',';
                                   if(field.dataType !='BOOLEAN'){
                                       soqlcondition += field.fieldAPIName + ' = \'' + field.selectedValues + '\' AND '; 
                                   }
                                   else{
                                       soqlcondition += field.fieldAPIName + ' = ' + field.selectedValues + ' AND ';  
                                   }
                                   
                                   
                               }
                            
                            if (field.fieldAPIName == fieldAPIName &&
                                field.selectedValues != null) {
                                    // Parse the selectedValues JSON string to get the Latitude and Longitude
                                    Map<String, Object> addressMap =
                                        (Map<String, Object>) JSON.deserializeUntyped(field.selectedValues);
                                    if (addressMap.containsKey('Latitude') &&
                                        addressMap.containsKey('Longitude')) {
                                            latitude = (decimal) addressMap.get('Latitude');
                                            longitude = (decimal) addressMap.get('Longitude');
                                        }
                                }
                        }
                    }
                } 
            }
            system.debug('latitude1::'+latitude+'longitude1::'+longitude);
            system.debug('soqlcondition::before'+soqlcondition);
            if (string.isNotBlank(soqlcondition) && soqlcondition.endsWith(' AND ')) {
                soqlcondition = soqlcondition.substring(0, soqlcondition.length() - 5);  // Remove the last ' AND '
            }
            system.debug('soqlcondition::'+soqlcondition);
            
            Id currentUserId = UserInfo.getUserId();
            
            System.debug('Input Parameters: Longitude = ' + longitude + ', Latitude = ' + latitude + ', Radius = ' + radius);
            list<Google_Map_Markers_Detail__c> lstGoogleMapMarkersDetail =
                new list<Google_Map_Markers_Detail__c>();
            List<sObject> lstSobject = new List<sObject>();
            List<SobjectAddress> lstsObjectAddresses = new List<SobjectAddress>();
            if(string.IsNotBlank(sObjectName)){
                String query = 'SELECT ID,Field_Name__c FROM Google_Map_Markers_Detail__c WHERE IsActive__c = true AND ';
                query += 'Google_Map_Config__r.object_name__c =\'' + sObjectName + '\'';
                system.debug('query::'+query);
                lstGoogleMapMarkersDetail = Database.query(query);
            }
            
            // Set's the default radius as 10
            if(String.valueOf(radius) == null){
                radius = '10';
            }
            
            if(longitude != null &&
               latitude != null &&
               Decimal.valueOf(radius) != null){
                   Decimal radiusValue = Decimal.valueOf(radius);
                   System.debug('Radius Value: ' + radiusValue);
                   
                   if(lstGoogleMapMarkersDetail != null && !lstGoogleMapMarkersDetail.isEmpty()){
                       for(SObject eachSObject : lstGoogleMapMarkersDetail){
                           if(String.isNotBlank((String)eachSObject.get('Field_Name__c'))){  
                               sobjectfieldNameToDisplay += eachSObject.get('Field_Name__c') + ',';
                           }
                          
                       }
                   }
                   if(sobjectfieldNameToDisplay.endsWith(',')){
                       sobjectfieldNameToDisplay = sobjectfieldNameToDisplay.removeEnd(',');
                   }
                   
                   String query = 'SELECT';
                   if (String.isNotBlank(sobjectfieldNameToDisplay)) {
                       query += ' ' + sobjectfieldNameToDisplay; 
                   }
                   /*if (String.isNotBlank(fieldAPIName)) {
query += ', ' + fieldAPIName; 
}*/
                   query += ' FROM ' + sObjectName;
                   query += ' WHERE DISTANCE(' + fieldAPIName + ', GEOLOCATION(' + latitude + ', ' + longitude + '), \'mi\') < ' + radiusValue;
                   if(string.isNotBlank(soqlcondition)){
                       query += ' AND '+soqlcondition;
                   }
                   query += ' LIMIT 100';
                   System.debug('SOQL Query: ' + query); 
                   lstSobject = Database.query(query);                
               }
            if (String.isNotBlank(sobjectfieldNameToDisplay)) {
                stringSet = new Set<String>(sobjectfieldNameToDisplay.split(',')); 
            }
            system.debug('lstSobject ::: ' + lstSobject);
            map<string,string> mapOfStringVsValue = new map<string,string>();
            List<DynamicWrapper> lstofDynamicWrapper = new List<DynamicWrapper>();
            if(lstSobject != null && !lstSobject.isEmpty()){
                for(SObject eachSObject :lstSobject){
                    system.debug('eachSObject ::: ' + eachSObject);
                    DynamicWrapper dynamicWrapper = new DynamicWrapper();
                    //Geolocation shippingAddress = new Geolocation();
                    if(stringSet != null && !stringSet.isEmpty()){
                        for(string eachString : stringSet){
                            Schema.SObjectField field = eachSObject.getSObjectType().getDescribe().fields.getMap().get(eachString);
                            Schema.DisplayType fieldType = field.getDescribe().getType();
                            if (fieldType == Schema.DisplayType.Address) {
                                // Serialize the Address field as a JSON string
                                String addressJson = JSON.serialize(eachSObject.get(eachString));
                                mapOfStringVsValue.put(eachString, addressJson);
                                dynamicWrapper.addField(eachString, addressJson);
                                
                                System.debug('Address field serialized as JSON: ' + addressJson);
                            } else {
                                system.debug('eachString::'+eachString);
                                mapOfStringVsValue.put(eachString,(string) eachSObject.get(eachString));
                                dynamicWrapper.addField(eachString, (String) eachSObject.get(eachString));
                            }
                            
                        }
                    }
                    //TODO : Need to update the wrapper 
                    /*If(eachSObject.get(fieldAPIName) != null){
                        //Geolocation billingCoordinates = new Geolocation();//String.valueOf(eachAccount.BillingLongitude),String.valueOf(eachAccount.BillingLatitude)
                        AddressWrapper sObjectAddress = new AddressWrapper(null,
                                                                           null,
                                                                           null,
                                                                           null,
                                                                           null,
                                                                           null,
                                                                           null,
                                                                           JSON.serialize(eachSObject.get(fieldAPIName)));
                        Boolean isOwner = false;
                        Schema.SObjectType objType = Schema.getGlobalDescribe().get(sObjectName);
                        if (objType != null && 
                            objType.getDescribe().fields.getMap().containsKey('OwnerId') &&
                            fieldAPIName.contains('OwnerId')) {
                                String ownerId = (String)eachSObject.get('OwnerId');
                                isOwner = (currentUserId == (ownerId != null ? ownerId : ''));
                            }
                        
                        lstsObjectAddresses.add(new SobjectAddress(
                            String.valueOf(eachSObject.get('Id')),  
                            null,
                            sObjectAddress,
                            isOwner,
                            null)); 
                    }*/
                    
                    lstofDynamicWrapper.add(dynamicWrapper);
                    
                }
                
                system.debug('lstofDynamicWrapper::'+lstofDynamicWrapper);
                
                system.debug('lstsObjectAddresses::'+lstsObjectAddresses);
                return AuraResponse = 
                    new AuraResponse(true ,'Success',JSON.serialize(lstofDynamicWrapper));
            }
            else{
                return AuraResponse = 
                    new AuraResponse(false ,'Error !!','No sObject Postal details found');  
            }
        } 
        catch(exception ex){
            system.debug('error in getting lst of sObject');
            System.debug('Error Message: ' + ex.getMessage());
            System.debug('Line Number: ' + ex.getLineNumber());
            System.debug('Exception Type: ' + ex.getTypeName());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
            return AuraResponse = new AuraResponse(false ,'Error',ex.getmessage());
        }
    }
    
    /*
* @author  		: Pushkar dahal
* @date    		: 22-Jan-2025
* @description	: This method is used to prepare HTTP Request
* @param 		: endPointUrl, requestMethod and requestTimeoOut used for setting up request to API
*/
    public static HttpRequest prepareRequest(String endPointUrl, String requestMethod,Integer requestTimeOut) {   
        system.debug('Preparing request');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        If(String.isNotBlank(endPointUrl) && String.isNotBlank(requestMethod) && requestTimeOut != Null ){
            request.setEndpoint(endPointUrl);
            request.setMethod(requestMethod);
            request.setTimeout(requestTimeOut);
        }
        return request;
    }
    
    /*
* @author 		: Pushkar dahal
* @date   		: 22-Jan-2025
* @description 	: Represents a single Account Addresses and Coordinates. 
* 				  This class defines the Shipping address coordinates, Billing address coordinates and billing address the for a single sObject record. 
* 				  These properties  correspond to fields on the sObject.
*/
    public class SobjectAddress{
        @AuraEnabled public String sObjectId; 
        @auraenabled public String sObjectName ;			
        @auraenabled public AddressWrapper sObjectAddress;
        @AuraEnabled public Boolean isOwner;
        @AuraEnabled public String sObjectOwner;	
        
        SobjectAddress(String sObjectId,
                       String sObjectName, 
                       AddressWrapper sObjectAddress ,
                       Boolean isOwner,
                       String sObjectOwner){
                           this.sObjectId = sObjectId; 
                           this.sObjectName = sObjectName;
                           this.sObjectAddress = sObjectAddress;
                           this.isOwner = isOwner;
                           this.sObjectOwner = sObjectOwner; 
                       }
    }
    /*
* @author 		: Pushkar dahal
* @date   		: 22-Jan-2025
* @description 	: Represents a single sObject Addresses.
* 				  This class defines the properties for a single  sObject Addresses record. 
* 				  
*/    
    public class AddressWrapper{
        @AuraEnabled public String sobjectStreet;
        @AuraEnabled public String sobjectCity;
        @AuraEnabled public String sobjectState;
        @AuraEnabled public String sobjectCountry;
        @AuraEnabled public String sobjectPostalCode;
        @AuraEnabled public Decimal sobjectBillingLongitude;
        @AuraEnabled public Decimal sobjectBillingLatitude;
        @AuraEnabled public string Address;
        
        AddressWrapper(){}
        
        AddressWrapper(	String sobjectStreet,
                       String sobjectCity,
                       String sobjectState,
                       String sobjectCountry,
                       String sobjectPostalCode,
                       Decimal sobjectBillingLongitude,
                       Decimal sobjectBillingLatitude,string address ){
                           this.sobjectStreet = sobjectStreet;
                           this.sobjectCity = sobjectCity;
                           this.sobjectState = sobjectState;
                           this.sobjectCountry = sobjectCountry;
                           this.sobjectPostalCode = sobjectPostalCode;
                           this.sobjectBillingLongitude = sobjectBillingLongitude;
                           this.sobjectBillingLatitude = sobjectBillingLatitude;
                           this.Address = Address;
                       }
    }
    /*
* @author 		: Pushkar dahal
* @date   		: 22-Jan-2025
* @description 	: Represents a single location longitude/latitude coordinates. 
*/
    public class Geolocation{
        @AuraEnabled public String longitude;
        @AuraEnabled public String latitude;
        
        Geolocation(){}
        
        Geolocation(
            String longitude,
            String latitude
        ){
            this.longitude = longitude;
            this.latitude = latitude;
        }   
    }
    
    /*
* @author 		: Pushkar dahal
* @date   		: 22-Jan-2025
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
    
    /*public class DynamicWrapper {
@AuraEnabled public Map<String,String> dynamicFields;
DynamicWrapper(){}
DynamicWrapper(Map<String,String> dynamicFields){
this.dynamicFields = dynamicFields;
} 
}*/
    public class DynamicWrapper {
        @AuraEnabled public Map<String, Object> dynamicFields;
        
        // Default Constructor
        public DynamicWrapper() {
            dynamicFields = new Map<String, Object>();
        }
        // Method to add dynamic field and its value
        public void addField(String fieldName, Object value) {
            dynamicFields.put(fieldName, value);
        }
        // Method to get the value of a field dynamically
        public Object getField(String fieldName) {
            return dynamicFields.get(fieldName);
        }
    }
    
    
}
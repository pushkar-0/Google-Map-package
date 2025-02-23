/* 
This class is used to validate sObject API name.
------------------------------------------------------------------------------------------------
Version#     Date                   Organization         Author                    Description
------------------------------------------------------------------------------------------------
1.0          11-Feb-2025       Kizzy Consulting      Pushkar dahal        	Initial Version
------------------------------------------------------------------------------------------------
*/
public class ValidateSobjectDetails {
    /*
* @author 		: Pushkar Dahal
* @date   		: 11-Feb-2025
* @description 	: This invocable method is used to display an error for an incorrect sObject API name.
* @param 		: fieldName
*/
    @InvocableMethod(label='Object Details' description='Display an error for an incorrect Object API name' category='Sobject Details')
    public static list<message> showErrorMessage(list<inputRequest> lstSobjectName) {
        system.debug('lstSobjectName::'+lstSobjectName);
        list<message> lstmessage = new list<message>();
        list<Google_Map_Config__c> lstGoogleMapConfig = new list<Google_Map_Config__c>();
        set<string> setOfsObjectName = new set<string>();
        Map<string,Integer> mapOfObjectNameVsSize = new Map<string,Integer>();
        try {
            if(lstSobjectName != null && !lstSobjectName.isEmpty()){
                for(inputRequest eachinputRequest : lstSobjectName){
                    setOfsObjectName.add(eachinputRequest.ObjectName);
                }
            }
            if(setOfsObjectName != null && !setOfsObjectName.isEmpty()){
                lstGoogleMapConfig = [SELECT id,Object_Name__c
                                      FROM Google_Map_Config__c
                                      WHERE IsActive__c = true 
                                      AND Object_Name__c IN :setOfsObjectName WITH SECURITY_ENFORCED ];
            }
            if(lstGoogleMapConfig != null && !lstGoogleMapConfig.isEmpty()){
                for(Google_Map_Config__c eachGoogleMapConfig : lstGoogleMapConfig){
                    if(string.isNotBlank(eachGoogleMapConfig.Object_Name__c) &&
                       !mapOfObjectNameVsSize.containsKey(eachGoogleMapConfig.Object_Name__c)){
                           mapOfObjectNameVsSize.put(eachGoogleMapConfig.Object_Name__c,1);
                       }else if(mapOfObjectNameVsSize.containsKey(eachGoogleMapConfig.Object_Name__c)){
                           mapOfObjectNameVsSize.put(eachGoogleMapConfig.Object_Name__c, 
                                                     mapOfObjectNameVsSize.get(eachGoogleMapConfig.Object_Name__c) + 1);
                       }
                }
            }
            if(lstSobjectName != null && !lstSobjectName.isEmpty()){
                for(inputRequest eachinputRequest : lstSobjectName){
                    if(String.isNotBlank(eachinputRequest.ObjectName)){
                        Schema.SObjectType objType = Schema.getGlobalDescribe().get(eachinputRequest.ObjectName);
                        if(objType != null && mapOfObjectNameVsSize.containsKey(eachinputRequest.ObjectName) && 
                           mapOfObjectNameVsSize.get(eachinputRequest.ObjectName) != null &&
                           mapOfObjectNameVsSize.get(eachinputRequest.ObjectName)>1){
                               lstmessage.add(new message(false,'Record with the same API name already exists.'));                           
                           } 
                        else if(objType == null){
                            lstmessage.add(new message(false,'Object API Name is invalid.'));  
                        }
                    }
                }
            }
        }
        catch (Exception e) {
            lstmessage.add(new message(false,'Invalid Record details.')); 
        }
        return lstmessage;
    }
    
    public class Message {
        @InvocableVariable public boolean Message;
        @InvocableVariable public string exceptionMessage; 
        public message(Boolean Message,string exceptionMessage) {
            this.Message = Message;
            this.exceptionMessage = exceptionMessage;
            
        }
    }
    public class InputRequest{
        @InvocableVariable(required=true)
        public String ObjectName;
    }  
}
/* 
This class is used to validate sObject field API name.
------------------------------------------------------------------------------------------------
Version#     Date                   Organization         Author                    Description
------------------------------------------------------------------------------------------------
1.0          30-Jan-2025       Kizzy Consulting      Pushkar dahal        	Initial Version
------------------------------------------------------------------------------------------------
*/ 
public class ValidateSobjectFieldAPIName {
    /*
* @author 		: Pushkar Dahal
* @date   		: 30-Jan-2025
* @description 	: This invocable method is used to display an error for an incorrect API name.
* @param 		: fieldName
*/
    @InvocableMethod(label='Object Details' description='Display an error for an incorrect API name' category='Sobject Details')
    public static list<message> showErrorMessage(list<inputRequest> fieldName) {
        Map<string,Integer> mapOfSobjectNameVsSize = new Map<string,Integer>();
        map<string,list<string>> mapOfsObjectNameVsListOfFields = new map<string,list<string>>();
        list<message> lstmessage = new list<message>();
        if(fieldName != null && !fieldName.isEmpty()){
            for(inputRequest eachinputRequest : fieldName){
                if(String.IsNotBlank(eachinputRequest.ObjectName)){
                    mapOfsObjectNameVsListOfFields.put(eachinputRequest.ObjectName,new list<string>());
                    if(mapOfsObjectNameVsListOfFields.containsKey(eachinputRequest.ObjectName)){
                        mapOfsObjectNameVsListOfFields.get(eachinputRequest.ObjectName).add(eachinputRequest.FieldName);
                    }
                }
            }
        }
        
        
        /*  Map<String, Schema.SObjectField> sObjectFields = record.getSObjectType().getDescribe().fields.getMap();

// Check if the field exists in the map
if (sObjectFields.containsKey(fieldName)) {*/
        if(!mapOfsObjectNameVsListOfFields.IsEmpty()){
            for(string eachsObject : mapOfsObjectNameVsListOfFields.keyset()){
                Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(eachsObject);
                if (sObjectType != null) {
                    Map<String, Schema.SObjectField> sObjectFields = sObjectType.getDescribe().fields.getMap();
                    for (String eachFieldName : mapOfsObjectNameVsListOfFields.get(eachsObject)) {
                        if (sObjectFields.containsKey(eachFieldName)) {
                            System.debug('Field ' + eachFieldName + ' exists on ' + eachsObject + '.');
                        } else {
                            lstmessage.add(new message(false));
                            System.debug('Field ' + eachFieldName + ' does not exist on ' + eachsObject + '.');
                        }
                    }
                }
            }
        }
        
        /*if(fieldName != null && !fieldName.isEmpty()){
            for(inputRequest eachinputRequest : fieldName){
                Type sObjectType = Type.forName(fieldName[0].ObjectName);
                SObject newSObject = (SObject)sObjectType.newInstance();
                
                
            }
        }*/
        
        
        /*list<message> lstmessage = new list<message>();
Type sObjectType = Type.forName(fieldName[0].ObjectName);
SObject newSObject = (SObject)sObjectType.newInstance();
Map<string,Integer> mapOfSobjectNameVsSize = new Map<string,Integer>();
set<string> setObjectName = new set<string>();
set<string> setFieldName = new set<string>();
system.debug('sObjectType::'+sObjectType+'   newSObject::'+newSObject);
list<Filter_Criteria__c> lstFilterCriteria = new list<Filter_Criteria__c>();
string objectAPIName;
list<sObject> lstsObject = new list<sObject>();
if(fieldName != null && !fieldName.isEmpty()){
for(inputRequest eachInputRequest : fieldName){
objectAPIName = eachInputRequest.ObjectAPIName;
if(string.IsNotBlank(eachInputRequest.ObjectName)){
setObjectName.add(eachInputRequest.ObjectName);
}if(string.IsNotBlank(eachInputRequest.FieldName)){
setFieldName.add(eachInputRequest.FieldName); 
}
}
}
// Check if both sets are not empty
if (!setObjectName.isEmpty() && !setFieldName.isEmpty()) {
// Construct the query using bind variables correctly
String query = 'SELECT Id, Google_Map_Config__c, Field_Name__c FROM ' + objectAPIName;
query += ' WHERE IsActive__c = true AND ';
query += 'Google_Map_Config__c IN :setObjectName AND Field_Name__c IN :setFieldName';
lstsObject = Database.query(query);

// Check if the query returns results
if (lstsObject != null && !lstsObject.isEmpty()) {
for (sObject eachsObject : lstsObject) {
if (String.isNotBlank((String) eachsObject.get('Field_Name__c')) && !mapOfSobjectNameVsSize.containsKey((String) eachsObject.get('Field_Name__c'))) {
mapOfSobjectNameVsSize.put((String) eachsObject.get('Field_Name__c'), 1);
} else if (mapOfSobjectNameVsSize.containsKey((String) eachsObject.get('Field_Name__c'))) {
mapOfSobjectNameVsSize.put((String) eachsObject.get('Field_Name__c'), mapOfSobjectNameVsSize.get((String) eachsObject.get('Field_Name__c')) + 1);
}

}
}
}


if(fieldName != null && !fieldName.isEmpty()){
for(inputRequest eachInputRequest : fieldName){
try{
Schema.DescribeFieldResult fieldResult = 
Schema.getGlobalDescribe().get(eachInputRequest.ObjectName).getDescribe().fields.getMap().get(eachInputRequest.FieldName).getDescribe();

system.debug('fieldResult::'+fieldResult);
}
catch(exception ex){
system.debug('enter in ex:'+ex);
lstmessage.add(new message(false));
}
}
}*/

return lstmessage;
    }
    
    public class Message {
        @InvocableVariable public boolean Message;
        public message(Boolean Message) {
            this.Message = Message;
            
        }
    }
    public class InputRequest{
        @InvocableVariable(required=true)
        public String FieldName;
        
        @InvocableVariable(required=true)
        public String ObjectName;
        
        @InvocableVariable
        public String ObjectAPIName;
        
    }
    
}
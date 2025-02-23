public without sharing class CustomlwcLookupController {

    @AuraEnabled
    public static List<RecordsData> fetchRecords(String objectName, String filterField, String searchString, String value, String otherFilterField , String filterValues ,String filterValue,String otherFilterField2, String oTHFfilterValue) {
        try {
            List<RecordsData> recordsDataList = new List<RecordsData>();
            String query = 'SELECT Id, ' + filterField + ' FROM '+objectName;
            if(String.isNotBlank(value)) {
                query += ' WHERE Id = \''+ value + '\' ';
            } else if(String.isNotBlank(otherFilterField)){
                if(String.isNotBlank(filterValue)){
                query += ' WHERE '+filterField+
                		' LIKE ' + '\'%' + String.escapeSingleQuotes(searchString.trim()) + '%\' AND '+'('+ otherFilterField +' = '+'\'' + String.escapeSingleQuotes(filterValues.trim()) + '\''+'OR '+ otherFilterField +' = '+'\'' + String.escapeSingleQuotes(filterValue.trim()) + '\''+')';
                    if(String.isNotBlank(otherFilterField2)){
                        query += ' AND '+ otherFilterField2 +' = '+'\'' + String.escapeSingleQuotes(oTHFfilterValue.trim()) + '\'';
                    }
                }else{
                query += ' WHERE '+filterField+
                		' LIKE ' + '\'%' + String.escapeSingleQuotes(searchString.trim()) + '%\' AND '+ otherFilterField +' = '+'\'' + String.escapeSingleQuotes(filterValues.trim()) + '\'';
                    if(String.isNotBlank(otherFilterField2)){
                        query += ' AND '+ otherFilterField2 +' = '+'\'' + String.escapeSingleQuotes(oTHFfilterValue.trim()) + '\'';
                    }
                }
            } else {
                query += ' WHERE '+filterField+
                		' LIKE ' + '\'%' + String.escapeSingleQuotes(searchString.trim()) + '%\'';
            }
            
            query += ' LIMIT 5';
            System.debug('query'+query);
            System.debug('query :::'+query);
	        for(SObject s : Database.query(query)) {
	            recordsDataList.add( new RecordsData((String)s.get(filterField), (String)s.get('id')) );
	        }
            return recordsDataList;
	    } catch (Exception err) {
	    	if ( String.isNotBlank( err.getMessage() ) && err.getMessage().contains( 'error:' ) ) {
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else {
                throw new AuraHandledException(err.getMessage());
            }
	    }
    }
 
    public class RecordsData {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public RecordsData(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}
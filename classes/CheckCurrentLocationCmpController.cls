/* 
This class provides methods to validate Current Location Logic to CheckCurrentLocationCmp LWC Component
------------------------------------------------------------------------------------------------
Version#     Date                   Organization         Author                    Description
------------------------------------------------------------------------------------------------
1.0          10-Oct-2024       Kizzy Consulting        Nitin               Initial Version
------------------------------------------------------------------------------------------------
*/ 
public class CheckCurrentLocationCmpController { 
    /**  
	* Retrieves Necessary data for Validation Logic.
	* @author  Nitin Agrahari : Kizzy Consulting.
	* @param RecordId The start date for filtering sessions.
	* @return AuraResponse Contains success status and serialized data or error message.
	*/
    @AuraEnabled
    public static AuraResponse handleValidateCurrentLocation(String accountDetails) {
        system.debug(' handleValidateCurrentLocation CALLED ');
        AuraResponse auraResponse;
        system.debug('accountDetails::'+accountDetails);
        try {
            if (String.isNotBlank(accountDetails)) {
                auraResponse = helperValidateCurrentLocation(accountDetails);
            } else {
                auraResponse = new AuraResponse(false, 'Error', 'RecordId or Latitude and Longitude is not found');
            }
        } catch (Exception ex) {
            System.debug('Error Message: ' + ex.getMessage());
            System.debug('Line Number: ' + ex.getLineNumber());
            System.debug('Exception Type: ' + ex.getTypeName());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
            auraResponse = new AuraResponse(false, 'Error', 'Error Message' + ex.getMessage() + ' ' +  'Line No:' + ex.getLineNumber());
        }
        return auraResponse;
    }    

    private static AuraResponse helperValidateCurrentLocation(String accountDetails){
        system.debug(' helperValidateCurrentLocation CALLED ');
        System.debug('helperValidateCurrentLocation: Method Entry with accountDetails: ' + accountDetails);
        AuraResponse auraResponse = new AuraResponse();
        
        AccountRecordLatLong wrapper = (AccountRecordLatLong) JSON.deserialize(accountDetails, AccountRecordLatLong.class);
        System.debug('Deserialized AccountRecordLatLong recordId: ' + wrapper.recordId);
        System.debug('Deserialized AccountRecordLatLong longitude: ' + wrapper.longitude);
        System.debug('Deserialized AccountRecordLatLong latitude: ' + wrapper.latitude);
        
        
        List<Account> lstOfAccountWithCurrentLocation = new List<Account>();
        // Gets the agent's visiting account dettails
        lstOfAccountWithCurrentLocation = [SELECT ID ,
                                           BillingLatitude,
                                           BillingLongitude
                                           FROM Account
                                           WHERE BillingLatitude != NULL
                                           AND BillingLongitude != NULL
                                           AND ID=:wrapper.recordId];
        
        System.debug('lstOfAccountWithCurrentLocation::'+lstOfAccountWithCurrentLocation);
        
        if (!lstOfAccountWithCurrentLocation.isEmpty()) {
            system.debug('lstOfAccountWithCurrentLocation[0] :::'+lstOfAccountWithCurrentLocation[0]);
            Account account = lstOfAccountWithCurrentLocation[0];
            
            // Calculate the distance using Haversine formula
            Double distanceInMeters = calculateHaversineDistance( (Double)wrapper.latitude, 
                                                                 (Double)wrapper.longitude, 
                                                                 (Double)account.BillingLatitude, 
                                                                 (Double)account.BillingLongitude);
            
            System.debug('Distance (in meters): ' + distanceInMeters);
            
            // Return true if the distance is less than 1 KM
            if (distanceInMeters < 1) {
                return new AuraResponse(true, 'Success', 'Reached Current Location');
            } else {
                return new AuraResponse(false, 'Failed', 'Still Away from Current Location');
            }
        } else {
            return new AuraResponse(false, 'Failed', 'Account location not found');
        }
    }

    private static Double calculateHaversineDistance(Double lat1, Double lon1, Double lat2, Double lon2) {
		system.debug(' calculateHaversineDistance CALLED ');
        Double R = 6371000; // Radius of Earth in meters
        
        Double latDistance = (lat2 - lat1) * (Math.PI / 180);
        Double lonDistance = (lon2 - lon1) * (Math.PI / 180);
        
        Double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2) +
            Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
            Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        
        Double distance = R * c;
        Decimal km = distance/1000;
        System.debug('Distance calculated: km ' + km);
        System.debug('Distance calculated: ' + distance);
        return km;
    }

   @AuraEnabled 
   public static AuraResponse helperUpdateLocationDetails(String recordId) {
	system.debug(' helperUpdateLocationDetails CALLED ');
    AuraResponse auraResponse; 
    List<Location_Details__c> lstOfLocationDetails = new List<Location_Details__c>();
    
    try {
        if(String.isNotBlank(recordId)){
            lstOfLocationDetails =  [SELECT Name, Id, 
                                     Status__c,
                                     Distance_Travelled__c,
                                     Source_Account_Address__c,
                                     Destination_Address__c
                                     FROM Location_Details__c
                                     WHERE Destination_Account__c =:recordId
                                     LIMIT 1];
            System.debug('Queried Location_Details__c Records: ' + lstOfLocationDetails);
        }

        if(!lstOfLocationDetails.isEmpty()){
            String destinationAddress = lstOfLocationDetails[0].Destination_Address__c;
            System.debug('Destination Address from Location Details: ' + destinationAddress);

            CalculatedDistance calculatedDistance = getDistance(lstOfLocationDetails[0].Source_Account_Address__c, lstOfLocationDetails[0].Destination_Address__c);
            
            System.debug('Distance API traveledKM: ' + calculatedDistance?.traveledKM);
            System.debug('Distance API duration: ' + calculatedDistance?.duartion);

            List<Location_Details__c> lstOfUpdatedLocationDetails = new List<Location_Details__c>();
            
            for(Location_Details__c eachLocationDetail : lstOfLocationDetails) {
                eachLocationDetail.Status__c = 'Check In';
                eachLocationDetail.Distance_Travelled__c = calculatedDistance?.traveledKM;
                lstOfUpdatedLocationDetails.add(eachLocationDetail);
            }

            if(!lstOfUpdatedLocationDetails.isEmpty()) {
                update lstOfUpdatedLocationDetails;
            }

            return new AuraResponse(true, 'Success', 'Checked In Successfully');
        }
    } catch (Exception ex) {
        System.debug('General Exception: ' + ex.getMessage());
        return new AuraResponse(false, 'Error', 'Unexpected Error: ' + ex.getMessage());
    }

    return new AuraResponse(false, 'Error', 'Record ID is blank or no data found');
}
    public static CalculatedDistance getDistance(String source, String destination) {
        System.debug('Calculating distance from Source: ' + source + ' to Destination: ' + destination);
        
        try {
            GoogleAPIService.DistanceMatrix distanceMatrix = new GoogleAPIService.DistanceMatrix(new List<String>{source}, new List<String>{destination});
            distanceMatrix = distanceMatrix.prepareRequest();
            
            System.debug('Prepared DistanceMatrix request: ' + distanceMatrix);
            
            distanceMatrix = distanceMatrix.sendRequest();
            HttpResponse response = distanceMatrix.getHttpResponse();
            
            System.debug('Received HTTP Response with status code: ' + response.getStatusCode());
            
            if (response.getStatusCode() == 200) {
                DistanceWrapper obj = DistanceWrapper.parse(response.getBody());
                DistanceWrapper.Rows row = (DistanceWrapper.Rows)obj.rows.get(0);
                DistanceWrapper.Elements elem = (DistanceWrapper.Elements)row.elements.get(0);
                DistanceWrapper.Distance dist = (DistanceWrapper.Distance)elem.distance;
                DistanceWrapper.Distance dura = (DistanceWrapper.Distance)elem.duration;
                
                System.debug('Parsed Distance: ' + dist.value + ' meters, Duration: ' + dura.value + ' seconds');
                
                return new CalculatedDistance(
                    (Decimal.valueOf(dist.value) / 1000).setScale(2), // Convert meters to kilometers
                    (Decimal.valueOf(dura.value) / 3600).setScale(2)  // Convert seconds to hours
                );
            } else {
                System.debug('Failed to retrieve distance. HTTP Status Code: ' + response.getStatusCode());
                return new CalculatedDistance(null, null);
            }
        } catch (Exception ex) {
            System.debug('An error occurred while calculating distance: ' + ex.getMessage());
            return new CalculatedDistance(null, null);
        }
    }
    
    public class AddressWrapper {
        public String Street;
        public String City;
        public String State;
        public String PostalCode;
        public String Country;
        
        public AddressWrapper(String Street, String City, String State, String PostalCode, String Country) {
            this.Street = Street;
            this.City = City;
            this.State = State;
            this.PostalCode = PostalCode;
            this.Country = Country;
        }
    }
    
    public class CalculatedDistance {
        public Decimal traveledKM;
        public Decimal duartion;
        
        public CalculatedDistance(Decimal traveledKM, Decimal duartion) {
            this.traveledKM = traveledKM;
            this.duartion = duartion;
        }
    }
    
    public class AccountRecordLatLong {
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;
        @AuraEnabled public String recordId;
        
        public AccountRecordLatLong(Decimal latitude, Decimal longitude, String recordId) {
            this.latitude = latitude;
            this.longitude = longitude; 
            this.recordId = recordId;
        }
    }
     
    public class AuraResponse {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String message;
        @AuraEnabled public String response;
        
        public AuraResponse(){ 
        }
        
        public AuraResponse(Boolean isSuccess, String message, String response) {
            this.isSuccess = isSuccess;
            this.message = message; 
            this.response = response;
        }
    }
}

   /*public class Geolocation{
        @AuraEnabled public String longitude;
        @AuraEnabled public String latitude;
        Geolocation(){
        }
        Geolocation(
            String longitude,
            String latitude
        ){
            this.longitude = longitude;
            this.latitude = latitude;
        }
        
    }*/

    /*@AuraEnabled
    public static AuraResponse handleUpdateLocationDetails(String recordId) {
        AuraResponse auraResponse;
        try {
            if (String.isNotBlank(recordId)) {
                helperUpdateLocationDetails(recordId);
            } else {
                auraResponse = new AuraResponse(false, 'Error', 'RecordId is not found');
            }
        } catch (Exception ex) {
            auraResponse = new AuraResponse(false, 'Error', 'Error Message' + ex.getMessage() + ' ' +  'Line No:' + ex.getLineNumber());
        }
        return auraResponse;
    }*/ 
    
    /*private static AuraResponse helperValidateCurrentLocation(String accountDetails){
        System.debug('helperValidateCurrentLocation: Method Entry with accountDetails: ' + accountDetails);
        AuraResponse auraResponse = new AuraResponse();
        
        AccountRecordLatLong wrapper = (AccountRecordLatLong) JSON.deserialize(accountDetails, AccountRecordLatLong.class);
        System.debug('Deserialized AccountRecordLatLong recordId: ' + wrapper.recordId);
        System.debug('Deserialized AccountRecordLatLong longitude: ' + wrapper.longitude);
        System.debug('Deserialized AccountRecordLatLong latitude: ' + wrapper.latitude);
        
        
        List<Account> lstOfAccountWithCurrentLocation = new List<Account>();
        lstOfAccountWithCurrentLocation = [SELECT ID ,
                                           BillingLatitude,
                                           BillingLongitude
                                           FROM Account
                                           WHERE DISTANCE(BillingAddress, GEOLOCATION(:wrapper.latitude,:wrapper.longitude), 'mi') < 1 
                                           AND ID=:wrapper.recordId];
                
        System.debug('lstOfAccountWithCurrentLocation::'+lstOfAccountWithCurrentLocation);
        
        if(!lstOfAccountWithCurrentLocation.isEmpty()){
            return new AuraResponse(true,'Success','Reached Current Location');
        }else{
            return new AuraResponse(false,'Failed','Still Away from Current Location');
        }
    }*/

    /*public static AuraResponse getCoordinates(String address, String radius) {
        System.debug('getCoordinates: Method Entry with address: ' + address + ' and radius: ' + radius);
        
        AuraResponse auraResponse;
        try {
            AddressWrapper newAddress = (AddressWrapper) JSON.deserialize(address, AddressWrapper.class);
            System.debug('Street: ' + newAddress.Street);
            System.debug('City: ' + newAddress.City);
            System.debug('State: ' + newAddress.State);
            System.debug('Country: ' + newAddress.Country);
            System.debug('PostalCode: ' + newAddress.PostalCode);
            
            String formattedAddress = newAddress?.Street + ', ' + newAddress?.City + ', ' + newAddress?.State + ', ' + newAddress?.PostalCode + ', ' + newAddress?.Country;
            System.debug('Formatted Address String for API Call: ' + formattedAddress);
            
            String apiUrl = 'https://nominatim.openstreetmap.org/search?q=' + EncodingUtil.urlEncode(formattedAddress, 'UTF-8') + '&format=json';
            System.debug('API URL: ' + apiUrl);
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(apiUrl);
            request.setMethod('GET');
            request.setTimeout(60000);
            
            System.debug('API Request Object: ' + request);
            HttpResponse response = http.send(request);
            System.debug('API Response Object: ' + response);
            
            if (response.getStatusCode() == 200) {
                System.debug('API Response Status: ' + response.getStatus() + ' and Body: ' + response.getBody());
                List<Object> lstResults = (List<Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('Parsed Results from API Response: ' + lstResults);
                
                if (lstResults.size() > 0) {
                    Map<String, Object> mapOfStringVsObject = (Map<String, Object>) lstResults[0];
                    System.debug('Location Data Map: ' + mapOfStringVsObject);
                    
                    if (mapOfStringVsObject != null && !mapOfStringVsObject.isEmpty() && mapOfStringVsObject.containsKey('lat') &&
                        mapOfStringVsObject.get('lat') != null && mapOfStringVsObject.containsKey('lon') &&
                        mapOfStringVsObject.get('lon') != null) {
                            
                            Decimal lon = mapOfStringVsObject.get('lon') != null ? Decimal.valueOf(String.valueOf(mapOfStringVsObject.get('lon'))) : 0;
                            Decimal lat = mapOfStringVsObject.get('lat') != null ? Decimal.valueOf(String.valueOf(mapOfStringVsObject.get('lat'))) : 0;
                            System.debug('Extracted Latitude: ' + lat + ' and Longitude: ' + lon);
                            
                            auraResponse = new AuraResponse(true, 'Success', JSON.serialize(new Map<String, String>{
                                'latitude' => String.valueOf(lat),
                                    'longitude' => String.valueOf(lon)
                                    }));
                            
                            return auraResponse;
                        }
                }
                return new AuraResponse(false, 'Error', 'No results found for the given address.');
            } else {
                return new AuraResponse(false, 'Error', 'Failed to get a response from the API. Status: ' + response.getStatus());
            }
        } catch (Exception ex) {
            System.debug('Exception in getCoordinates: ' + ex.getMessage());
            System.debug('Line Number: ' + ex.getLineNumber());
            System.debug('Exception Type: ' + ex.getTypeName());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
            
            return new AuraResponse(false, 'Error', 'Exception occurred: ' + ex.getMessage());
        }
    }
    
    public static AddressWrapper splitAddressFields(String fullAddress) {
        List<String> addressParts = fullAddress != null ? fullAddress.split(',') : new List<String>();
        
        for (Integer i = 0; i < addressParts.size(); i++) {
            addressParts[i] = addressParts[i].trim();
        }
        
        String Street = addressParts.size() > 0 ? addressParts[0] : '';
        String City = addressParts.size() > 1 ? addressParts[1] : '';
        String State = addressParts.size() > 2 ? addressParts[2] : '';
        String PostalCode = addressParts.size() > 3 ? addressParts[3] : '';
        String Country = addressParts.size() > 4 ? addressParts[4] : '';
        
        return new AddressWrapper(Street, City, State, PostalCode, Country);
    }*/
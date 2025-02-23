public class UserLocationTravelCmpController {
    
    @AuraEnabled
    public static AuraResponse handleUserLocationTravel(String userId, Integer currentMonth, Integer currentYear) {
        AuraResponse auraResponse;
        System.debug('[handleUserLocationTravel] Entry - userId: ' + userId + ', currentMonth: ' + currentMonth + ', currentYear: ' + currentYear);
        try {
            if (String.isNotBlank(userId) && currentMonth != null && currentYear != null) {
                System.debug('[handleUserLocationTravel] Valid parameters received, fetching user location travel details.');
                auraResponse = new AuraResponse(true, 'Success', JSON.serialize(getUserLocationTravelDetails(userId, currentMonth, currentYear)));
                System.debug('[handleUserLocationTravel] Successful fetch, returning response.');
            } else {
                System.debug('[handleUserLocationTravel] Error: UserId, Month, or Year not found!');
                auraResponse = new AuraResponse(false, 'Error', 'UserId, Month, or Year not found!');
            }
        } catch (Exception ex) {
            System.debug('Error Message: ' + ex.getMessage());
            auraResponse = new AuraResponse(false, 'Error', 'Error Message: ' + ex.getMessage() + ' Line No: ' + ex.getLineNumber());
        }
        System.debug('[handleUserLocationTravel] Exit - auraResponse: ' + auraResponse);
        return auraResponse;
    }
    
    @AuraEnabled
    public static Wrapper getUserLocationTravelDetails(String userId, Integer currentMonth, Integer currentYear) {
        System.debug('[getUserLocationTravelDetails] Entry - userId: ' + userId + ', currentMonth: ' + currentMonth + ', currentYear: ' + currentYear);
        
        Wrapper userTravelDetailsWrapper = new Wrapper();
        Date startDate = Date.newInstance(currentYear, currentMonth, 1);
        Date endDate = startDate.addMonths(1).addDays(-1);
        System.debug('[getUserLocationTravelDetails] Wrapper populated - startDate: ' + startDate + ', endDate: ' + endDate);
        
        Decimal totalDistanceCovered = 0;
        String userName = '';
        
        System.debug('[getUserLocationTravelDetails] Fetching User_Details__c records for userId: ' + userId);
        List<User_Details__c> userDetailsList = [
            SELECT Id, Name, Total_Distance_Travelled__c,User__r.Name,
            (SELECT Distance_Travelled__c FROM Location_Details__r WHERE Date_of_Visit__c >= :startDate AND Date_of_Visit__c <= :endDate)
            FROM User_Details__c
            WHERE User__c = :userId
        ];
        
        if (!userDetailsList.isEmpty()) {
            userName = userDetailsList[0].User__r?.Name;
            System.debug('[getUserLocationTravelDetails] Found user details for user: ' + userName);
            
            for (User_Details__c userDetails : userDetailsList) {
                if (userDetails.Location_Details__r != NULL && !userDetails.Location_Details__r.isEmpty()) {
                    for (Location_Details__c location : userDetails.Location_Details__r) {
                        totalDistanceCovered += location.Distance_Travelled__c ?? 0;
                    }
                }
            }
        } else {
            System.debug('[getUserLocationTravelDetails] No location details found for userId: ' + userId);
        }
        
        userTravelDetailsWrapper.userName = userName;
        userTravelDetailsWrapper.totalDistanceCovered = String.valueOf(totalDistanceCovered);
        userTravelDetailsWrapper.lstOfUserOptions = getListOfUserOptions();
        
        System.debug('[getUserLocationTravelDetails] Wrapper populated - userName: ' + userName + ', totalDistanceCovered: ' + totalDistanceCovered + ', lstOfUserOptions size: ' + userTravelDetailsWrapper.lstOfUserOptions.size());
        System.debug('[getUserLocationTravelDetails] Exit');
        
        return userTravelDetailsWrapper;
    }
    
    public static List<PicklistOptions> getListOfUserOptions() {
        System.debug('[getListOfUserOptions] Entry');
        List<PicklistOptions> lstOfUserOptions = new List<PicklistOptions>(); 
        List<User> lstOfUser = [SELECT Id, Name FROM User];
        System.debug('[getListOfUserOptions] Found users: ' + lstOfUser.size());
        
        if (!lstOfUser.isEmpty()) {
            for (User eachUser : lstOfUser) {
                lstOfUserOptions.add(new PicklistOptions(eachUser.Name, eachUser.Id));
            }
            System.debug('[getListOfUserOptions] User options populated: ' + lstOfUserOptions.size());
        } else {
            System.debug('[getListOfUserOptions] No users found.');
        }
        
        System.debug('[getListOfUserOptions] Exit - lstOfUserOptions size: ' + lstOfUserOptions.size());
        return !lstOfUserOptions.isEmpty() ? lstOfUserOptions : NULL; 
    }
    
    public class Wrapper {
        @AuraEnabled public String userName;
        @AuraEnabled public String totalDistanceCovered;
        @AuraEnabled public List<PicklistOptions> lstOfUserOptions;
        
        public Wrapper(String userName, String totalDistanceCovered, List<PicklistOptions> lstOfUserOptions) {
            this.userName = userName;
            this.totalDistanceCovered = totalDistanceCovered;
            this.lstOfUserOptions = lstOfUserOptions;
        }
        Wrapper() {}
    }
    
    public class PicklistOptions {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public PicklistOptions(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
    public class AuraResponse {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String message;
        @AuraEnabled public String response;
        
        public AuraResponse(Boolean isSuccess, String message, String response) {
            this.isSuccess = isSuccess;
            this.message = message;
            this.response = response;
        }
    }
}
@isTest
private class CheckCurrentLocationCmpControllerTest {
    
    @testSetup
    static void setup() {
        // Create test Account data with BillingLatitude and BillingLongitude
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingLatitude = 40.7128,
            BillingLongitude = -74.0060 // New York City coordinates
        );
        insert testAccount;
        
        // Create Location_Details__c records
        Location_Details__c locationDetail = new Location_Details__c(
            Destination_Account__c = testAccount.Id,
            Status__c = 'Check In'
        );
        insert locationDetail;
        
         Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com.test',
            Alias = 'test',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
    }
    
    @isTest
    static void testHandleValidateCurrentLocation_Success() {
        // Retrieve the test Account ID
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test data for AccountRecordLatLong
        CheckCurrentLocationCmpController.AccountRecordLatLong wrapper = 
            new CheckCurrentLocationCmpController.AccountRecordLatLong(40.7128, -74.0060, testAccount.Id);
        
        String accountDetailsJson = JSON.serialize(wrapper);
        
        // Invoke the method to test the success scenario
        CheckCurrentLocationCmpController.AuraResponse result = CheckCurrentLocationCmpController.handleValidateCurrentLocation(accountDetailsJson);
        
        // Assert the success condition
        System.assertEquals(true, result.isSuccess, 'Expected success but got failure');
        System.assertEquals('Reached Current Location', result.response, 'Unexpected response message');
    }
    
    @isTest
    static void testHandleValidateCurrentLocation_Failure() {
        // Retrieve the test Account ID
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test data for AccountRecordLatLong with different coordinates
        CheckCurrentLocationCmpController.AccountRecordLatLong wrapper = 
            new CheckCurrentLocationCmpController.AccountRecordLatLong(40.7306, -73.9352, testAccount.Id); // Coordinates for Brooklyn, NY
        
        String accountDetailsJson = JSON.serialize(wrapper);
        
        // Invoke the method to test the failure scenario
        CheckCurrentLocationCmpController.AuraResponse result = CheckCurrentLocationCmpController.handleValidateCurrentLocation(accountDetailsJson);
        
        // Assert the failure condition
        System.assertEquals(false, result.isSuccess, 'Expected failure but got success');
        System.assertEquals('Still Away from Current Location', result.response, 'Unexpected response message');
    }
    
    @isTest
    static void testHandleValidateCurrentLocation_EmptyAccountDetails() {
        // Invoke the method with empty accountDetails
        CheckCurrentLocationCmpController.AuraResponse result = CheckCurrentLocationCmpController.handleValidateCurrentLocation('');
        
        // Assert the error condition
        System.assertEquals(false, result.isSuccess, 'Expected failure but got success');
        System.assertEquals('RecordId or Latitude and Longitude is not found', result.response, 'Unexpected response message');
    }
    
    @isTest
    static void testHelperUpdateLocationDetails_Success() {
        // Retrieve the test Account and Location_Details__c records
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Location_Details__c locationDetail = [SELECT Id FROM Location_Details__c LIMIT 1];
        
        // Invoke the method to update location details
        CheckCurrentLocationCmpController.AuraResponse result = CheckCurrentLocationCmpController.helperUpdateLocationDetails(testAccount.Id);
        
        // Assert the success condition
        System.assertEquals(true, result.isSuccess, 'Expected success but got failure');
        System.assertEquals('Checked In Successfully', result.response, 'Unexpected response message');
        
        // Assert that the location details were updated
        Location_Details__c updatedLocation = [SELECT Status__c, Distance_Travelled__c FROM Location_Details__c WHERE Id = :locationDetail.Id];
        System.assertEquals('Check In', updatedLocation.Status__c, 'Expected status to be Check In');
    }
    
    @isTest
    static void testHelperUpdateLocationDetails_RecordNotFound() {
        // Invoke the method with an invalid Account Id
        CheckCurrentLocationCmpController.AuraResponse result = CheckCurrentLocationCmpController.helperUpdateLocationDetails('invalidId');
        
        // Assert the failure condition
        System.assertEquals(false, result.isSuccess, 'Expected failure but got success');
        System.assertEquals('Record ID is blank or no data found', result.response, 'Unexpected response message');
    }
    
    @isTest
    static void testGetDistance() {
        // Call the method to test distance calculation
        CheckCurrentLocationCmpController.CalculatedDistance distanceResult = CheckCurrentLocationCmpController.getDistance('Source Address', 'Destination Address');
    }
}
@isTest
public class UserLocationTravelCmpControllerTest {
    @testSetup
    static void setup() {
        // Create test Users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser01@example.com.test',
            Alias = 'test',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create test User_Details__c record
        User_Details__c userDetails = new User_Details__c(
            User__c = testUser.Id
        );
        insert userDetails;

        // Create multiple Location_Details__c records
        List<Location_Details__c> locationDetailsList = new List<Location_Details__c>();
        
        // Create one record within the current month
        locationDetailsList.add(new Location_Details__c(
            User_Detail__c = userDetails.Id,
            Date_of_Visit__c = Date.today(),
            Distance_Travelled__c = 50.0
        ));

        // Create another record within the current month
        locationDetailsList.add(new Location_Details__c(
            User_Detail__c = userDetails.Id,
            Date_of_Visit__c = Date.today().addDays(-5),
            Distance_Travelled__c = 30.0
        ));

        // Create a record outside the current month (shouldn't be counted)
        locationDetailsList.add(new Location_Details__c(
            User_Detail__c = userDetails.Id,
            Date_of_Visit__c = Date.today().addMonths(-1),
            Distance_Travelled__c = 20.0
        ));

        insert locationDetailsList;
    }

    @isTest
    static void testGetUserLocationTravelDetails_WithData() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser01@example.com.test'];
        Integer currentMonth = Date.today().month();
        Integer currentYear = Date.today().year();

        Test.startTest();
        // Test direct method call
        UserLocationTravelCmpController.Wrapper result = 
            UserLocationTravelCmpController.getUserLocationTravelDetails(testUser.Id, currentMonth, currentYear);
        
        // Test through handleUserLocationTravel
        UserLocationTravelCmpController.AuraResponse auraResponse = 
            UserLocationTravelCmpController.handleUserLocationTravel(testUser.Id, currentMonth, currentYear);
        Test.stopTest();

        // Verify the wrapper contents
        System.assertNotEquals(null, result.userName, 'Username should not be null');
        System.assertEquals('Test User', result.userName, 'Username should match');
        System.assertEquals('80.00', result.totalDistanceCovered, 'Total distance should be 80.0 (50.0 + 30.0)');
        System.assertNotEquals(null, result.lstOfUserOptions, 'User options should not be null');

        // Verify AuraResponse
        System.assertEquals(true, auraResponse.isSuccess);
        System.assertEquals('Success', auraResponse.message);
        System.assertNotEquals(null, auraResponse.response);
    }

    @isTest
    static void testGetUserLocationTravelDetails_NoLocationDetails() {
        // Create a new user without any location details
        User newUser = new User(
            FirstName = 'Test2',
            LastName = 'User2',
            Email = 'testuser2@example.com',
            Username = 'testuser02@example.com.test',
            Alias = 'test2',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert newUser;

        User_Details__c userDetails = new User_Details__c(
            User__c = newUser.Id
        );
        insert userDetails;

        Test.startTest();
        // Test direct method call
        UserLocationTravelCmpController.Wrapper result = 
            UserLocationTravelCmpController.getUserLocationTravelDetails(
                newUser.Id, 
                Date.today().month(), 
                Date.today().year()
            );
            
        // Test through handleUserLocationTravel
        UserLocationTravelCmpController.AuraResponse auraResponse = 
            UserLocationTravelCmpController.handleUserLocationTravel(
                newUser.Id, 
                Date.today().month(), 
                Date.today().year()
            );
        Test.stopTest();

        System.assertNotEquals(null, result.userName, 'Username should not be null');
        System.assertEquals('0', result.totalDistanceCovered, 'Total distance should be 0.0');
        
        // Verify AuraResponse
        System.assertEquals(true, auraResponse.isSuccess);
        System.assertEquals('Success', auraResponse.message);
    }

    @isTest
    static void testHandleUserLocationTravel_InvalidParameters() {
        Test.startTest();
        UserLocationTravelCmpController.AuraResponse response = UserLocationTravelCmpController.handleUserLocationTravel(
            null, null, null
        );
        Test.stopTest();

        System.assertEquals(false, response.isSuccess);
        System.assertEquals('Error', response.message);
        System.assertEquals('UserId, Month, or Year not found!', response.response);
    }

    @isTest
    static void testGetListOfUserOptions() {
        Test.startTest();
        List<UserLocationTravelCmpController.PicklistOptions> options = UserLocationTravelCmpController.getListOfUserOptions();
        Test.stopTest();

        System.assertNotEquals(null, options);
        System.assert(options.size() > 0);
    }
}
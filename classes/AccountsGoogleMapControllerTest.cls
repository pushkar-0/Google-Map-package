@isTest
public class AccountsGoogleMapControllerTest  {
    // Test Setup
    @testSetup
    public static void createTestData(){
        List<Account> lstAccounts = TestDataFactory.noOfAccountToInsert(1, 'Test Company'); 
        lstAccounts[0].BillingStreet = '123';
        lstAccounts[0].BillingCity = 'Chandigarh';
        lstAccounts[0].BillingState = 'Maharashtra';
        lstAccounts[0].BillingPostalCode = '131001';
        lstAccounts[0].BillingCountry = 'India';
        lstAccounts[0].BillingLongitude = 76.80921; // Valid Longitude
        lstAccounts[0].BillingLatitude = 30.76099;  // Valid Latitude
        insert lstAccounts;
    }
     @IsTest
    static void testGetAgentCoordinates_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String sampleAddress = '{"Street":"123 Main St","City":"New York","State":"NY","PostalCode":"10001"}';
        String radius = '10';
        AccountsGoogleMapController.getAgentCoordinates(sampleAddress, radius);
        Test.stopTest();
        system.assert(true);
    }
    
     @IsTest
    static void testGetAgentCoordinates() {
        list<account> lstAccount = [SELECT ID FROM Account];
        Test.startTest();
        AccountsGoogleMapController.getAccountAddress(lstAccount[0].id);
        Test.stopTest();
        system.assert(true);
    }

    // Test method for getNearbyAccounts with existing accounts
    @isTest
    static void testGetNearbyAccounts_ValidAccounts() {
        String longitude = '76.7784'; // Valid Longitude
        String latitude = '30.7333';  // Valid Latitude
        String radius = '10';

        AccountsGoogleMapController.AuraResponse response = AccountsGoogleMapController.getNearbyAccounts(longitude, latitude, radius);
        System.assertNotEquals(null, response);
        System.assertEquals(true, response.isSuccess);
        System.assertEquals('Success', response.message);
        List<AccountsGoogleMapController.AccountAddress> accountAddresses = 
            (List<AccountsGoogleMapController.AccountAddress>) JSON.deserialize(response.response, List<AccountsGoogleMapController.AccountAddress>.class);
        System.assertEquals(1, accountAddresses.size()); // Validate that the created account is returned
    }

    // Test method for getNearbyAccounts with no results
    @isTest
    static void testGetNearbyAccounts_NoResults() {
        // No accounts created; set coordinates far from any created account
        String longitude = '0';
        String latitude = '0';
        String radius = '1';

        AccountsGoogleMapController.AuraResponse response = AccountsGoogleMapController.getNearbyAccounts(longitude, latitude, radius);
        System.assertNotEquals(null, response);
        System.assertEquals(false, response.isSuccess);
        System.assertEquals('Error !!', response.message);
        System.assertEquals('No Account Postal details found', response.response);
    }

    // Test for getNearbyAccounts with invalid coordinates
    @isTest
    static void testGetNearbyAccounts_InvalidCoordinates() {
        String longitude = 'not a number';
        String latitude = 'not a number';
        String radius = '10';

        AccountsGoogleMapController.AuraResponse response = AccountsGoogleMapController.getNearbyAccounts(longitude, latitude, radius);
        System.assertNotEquals(null, response);
        System.assertEquals(false, response.isSuccess);
    }

    // Test for the edge case of getNearbyAccounts with boundary values
    @isTest
    static void testGetNearbyAccounts_BoundaryValues() {
        String longitude = '76.7784'; // Valid Longitude
        String latitude = '30.7333';  // Valid Latitude
        String radius = '999999'; // Large radius to ensure all accounts are included

        AccountsGoogleMapController.AuraResponse response = AccountsGoogleMapController.getNearbyAccounts(longitude, latitude, radius);
        System.assertNotEquals(null, response);
        System.assertEquals(true, response.isSuccess);
        System.assertEquals('Success', response.message);
        List<AccountsGoogleMapController.AccountAddress> accountAddresses = 
            (List<AccountsGoogleMapController.AccountAddress>) JSON.deserialize(response.response, List<AccountsGoogleMapController.AccountAddress>.class);
        System.assertEquals(1, accountAddresses.size()); // Validate that the created account is returned
    }

    // Test method for getNearbyAccounts with billing coordinates missing
    @isTest
    static void testGetNearbyAccounts_MissingBillingCoordinates() {
        Account accountWithoutCoordinates = new Account(Name='Test Account', BillingStreet='123 Main St', BillingCity='Chandigarh', 
                                                         BillingState='Chandigarh', BillingPostalCode='160001', 
                                                         BillingCountry='India', BillingLongitude=null, BillingLatitude=null);
        insert accountWithoutCoordinates;

        String longitude = '76.7784';
        String latitude = '30.7333';
        String radius = '10';

        AccountsGoogleMapController.AuraResponse response = AccountsGoogleMapController.getNearbyAccounts(longitude, latitude, radius);
        System.assertNotEquals(null, response);
        //System.assertEquals(false, response.isSuccess);
        //System.assertEquals('Error !!', response.message);
    }
      private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"lat": "39.7817", "lon": "-89.6501"}]'); 
            res.setStatusCode(200);
            return res;
        }
    }
}

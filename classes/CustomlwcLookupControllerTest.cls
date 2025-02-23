@isTest
public class CustomlwcLookupControllerTest {
    
    @isTest
    public static void testFetchRecords() {
        // Test data
        Account testAccount = new Account(Name = 'Test Account', Fax = '112233', Phone='123456');
        insert testAccount;
        String value = testAccount.Id;
        
        // Call the method with various scenarios
        List<CustomlwcLookupController.RecordsData> result1 = CustomlwcLookupController.fetchRecords('Account', 'Name', '', '', '', '', '','Phone','123456');
        List<CustomlwcLookupController.RecordsData> result2 = CustomlwcLookupController.fetchRecords('Account', 'Name', '', '', 'Fax', '112233', '','Phone','123456');
        List<CustomlwcLookupController.RecordsData> result3 = CustomlwcLookupController.fetchRecords('Account', 'Name', '', value, '', '', '','Phone','123456');
        List<CustomlwcLookupController.RecordsData> result4 = CustomlwcLookupController.fetchRecords('Account', 'Name', '', value, 'Fax', '112233', '113344','Phone','123456');
        List<CustomlwcLookupController.RecordsData> result5 = CustomlwcLookupController.fetchRecords('Account', 'Name', '', null, 'Fax', '112233', '113344','Phone','123456');
        
        // Assertions
        System.assertEquals(1, result1.size(), 'Expected one record to be returned for result1');
        CustomlwcLookupController.RecordsData record1 = result1[0];
        System.assertEquals(testAccount.Name, record1.label, 'Incorrect record label for result1');
        System.assertEquals(testAccount.Id, record1.value, 'Incorrect record value for result1');
        
        System.assertEquals(1, result2.size(), 'Expected one record to be returned for result2');
        CustomlwcLookupController.RecordsData record2 = result2[0];
        System.assertEquals(testAccount.Name, record2.label, 'Incorrect record label for result2');
        System.assertEquals(testAccount.Id, record2.value, 'Incorrect record value for result2');
        
        System.assertEquals(1, result3.size(), 'Expected one record to be returned for result3');
        CustomlwcLookupController.RecordsData record3 = result3[0];
        System.assertEquals(testAccount.Name, record3.label, 'Incorrect record label for result3');
        System.assertEquals(testAccount.Id, record3.value, 'Incorrect record value for result3');
        
        // Add more assertions for other test cases as needed
    }
    
    @isTest
    public static void testFetchRecords_Exception() {
        try {
            // Call the method with an invalid object name
            List<CustomlwcLookupController.RecordsData> result = CustomlwcLookupController.fetchRecords('InvalidObject', 'Name', 'Test', '', '', '', '','Phone','123456');
        } catch (AuraHandledException e) {
            // Exception should be thrown
            System.assertNotEquals(null, e.getMessage(), 'Expected exception message');
        }
    }
}
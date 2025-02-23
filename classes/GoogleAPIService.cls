public with sharing class GoogleAPIService {

    /**
     * @description Distance Matrix API
     *  https://developers.google.com/maps/documentation/distance-matrix/overview
     * @usage
     *  List<String> originAddresses = new List<String> { someAddress1 };
     *  List<String> destinationAddresses = new List<String> { someAddress2 };
     *  GoogleAPIService.DistanceMatrix gService = new GoogleAPIService.DistanceMatrix(originAddresses, destinationAddresses);
     *  GoogleResponse resp = gService.prepareRequest().sendRequest().getGoogleResponse();
     */
    public class DistanceMatrix {
        List<Google_API_Configuration__mdt> apiInfo = [SELECT Id, Key__c, Endpoint_URL__c FROM Google_API_Configuration__mdt WHERE DeveloperName = 'Google_Distance_Matrix'];
        private final String API_KEY = apiInfo.isEmpty() ? null : apiInfo[0].Key__c; 
        private final String LANGUAGE = 'en';
        private final String MODE = 'DRIVING';
        private final String BASE_URL = apiInfo.isEmpty() ? null : apiInfo[0].Endpoint_URL__c;//'https://maps.googleapis.com/maps/api/distancematrix/json?';

        @TestVisible
        private List<String> originList;
        @TestVisible
        private List<String> destinationList;
        @TestVisible
        private HttpRequest request;
        @TestVisible
        private HttpResponse response;
        @TestVisible
        private GoogleResponse gResponse;

        /**
         * @description expects an unencoded String or addresses.
         *  Check documentation to ensure addresses are in the right order within the list
         */
        public DistanceMatrix(List<String> orig, List<String> dest) {
            this.originList = orig;
            this.destinationList = dest;
        }

        /**
         * @description prepare HTTP Request
         */
        public DistanceMatrix prepareRequest() {
            String url = buildEndpointUrl();
            this.request = new HttpRequest();
            this.request.setMethod('GET');
            this.request.setEndPoint(url);
            return this;
        }
        /**
         * @description send HTTP Request
         */
        public DistanceMatrix sendRequest() {
            this.response = new Http().send(this.request);
            this.gResponse = GoogleResponse.parse(this.response.getBody());
            system.debug('gResponse::'+this.gResponse);
            return this;
        }

        //getters

        public HttpRequest getRequest() {
            return this.request;
        }

        public HttpResponse getHttpResponse() {
            return this.response;
        }

        public GoogleResponse getGoogleResponse() {
            return this.gResponse;
        }

        //private

        /**
         * @description build the endpoint URL with all the parameters
         */
        @TestVisible
        private String buildEndpointUrl() {
            String strOrigin = buildAddressArray(this.originList);
            String strDestination = buildAddressArray(this.destinationList);
            return String.format('{0}origins={1}&destinations={2}&mode={3}&language={4}&key={5}',
                new List<String> {
                    this.BASE_URL,
                    strOrigin,
                    strDestination,
                    this.MODE,
                    this.LANGUAGE,
                    this.API_KEY
            });
        }

        /**
         * @description builds an "array" of address and:
         *  1. url encode - e.g. replace spaces with %20
         *  2. delimit all address entries with a pipe
         */
        @TestVisible
        private String buildAddressArray(List<String> addList) {
            return '['+EncodingUtil.urlEncode(String.join(addList, '|'), 'UTF-8')+']';
        }
    }
}
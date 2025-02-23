/**
 * @description       : Google response data structure
 * @group             : Google APIs
 */
public class GoogleResponse {

    public List<String> destination_addresses;
    public List<String> origin_addresses;
    public List<Rows> rows;
    public String status;

    public class Elements {
        public Distance distance;
        public Distance duration;
        public String status;
    }

    public class Distance {
        public String text;
        public Integer value;
    }

    public class Rows {
        public List<Elements> elements;
    }

    public static GoogleResponse parse(String json) {
        system.debug('json::'+json);
        return (GoogleResponse) System.JSON.deserialize(json, GoogleResponse.class);
    }
}
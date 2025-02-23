public class DistanceWrapper {
    
    public class Elements {
        public Distance distance;
        public Distance duration;
        public String status;
    }
    
    public class Distance {
        public String text;
        public Integer value;
    }
    
    public List<String> destination_addresses;
    public List<String> origin_addresses;
    public List<Rows> rows;
    public String status;
    
    public class Rows {
        public List<Elements> elements;
    }
    
    
    public static DistanceWrapper parse(String json) {
        return (DistanceWrapper) System.JSON.deserialize(json, DistanceWrapper.class);
    }
}
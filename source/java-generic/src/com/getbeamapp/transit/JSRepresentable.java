package com.getbeamapp.transit;

public interface JSRepresentable {
    public String getJSRepresentation();
    
    public class Expression implements JSRepresentable {
        private String expression;

        public Expression(String s) {
            this.expression = s;
        }
        
        @Override
        public String getJSRepresentation() {
            return expression;
        }
    }
}

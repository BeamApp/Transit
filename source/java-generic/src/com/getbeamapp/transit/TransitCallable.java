package com.getbeamapp.transit;

public interface TransitCallable {
    public Object evaluate(Object thisArg, Object... arguments);
    
    public static final TransitCallable NOOP = new TransitCallable() {
        @Override
        public Object evaluate(Object thisArg, Object... arguments) {
            return null;
        }
    };
}

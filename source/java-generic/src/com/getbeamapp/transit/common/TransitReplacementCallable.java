package com.getbeamapp.transit.common;

public interface TransitReplacementCallable {
    public Object evaluate(TransitJSFunction original, Object thisArg, Object... arguments);
}

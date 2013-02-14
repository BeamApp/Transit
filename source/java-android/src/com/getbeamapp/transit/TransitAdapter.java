package com.getbeamapp.transit;

public interface TransitAdapter {
    void initialize();

    TransitProxy evaluate(String stringToEvaluate, JSRepresentable thisArg, JSRepresentable... arguments);
    
    void releaseProxy(String proxyId);
}

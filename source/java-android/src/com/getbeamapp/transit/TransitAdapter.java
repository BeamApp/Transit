package com.getbeamapp.transit;

public interface TransitAdapter {
    void initialize();

    Object evaluate(String stringToEvaluate);
    
    void releaseProxy(String proxyId);
}

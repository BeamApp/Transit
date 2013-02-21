package com.getbeamapp.transit.android;

public interface TransitAdapter {
    void initialize();
    
    void releaseProxy(String proxyId);
    
    void evaluateAsync(String stringToEvaluate);
    
    Object evaluate(String stringToEvaluate);
}

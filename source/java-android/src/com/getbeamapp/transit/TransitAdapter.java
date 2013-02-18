package com.getbeamapp.transit;

public interface TransitAdapter {
    void initialize();
    
    void releaseProxy(String proxyId);
    
    void evaluateAsync(String stringToEvaluate);
    
    Object evaluate(String stringToEvaluate);
}

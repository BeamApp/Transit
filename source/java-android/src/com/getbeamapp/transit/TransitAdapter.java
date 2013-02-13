package com.getbeamapp.transit;

public interface TransitAdapter {
    void initialize();

    TransitProxy evaluate(String stringToEvaluate, JavaScriptRepresentable thisArg, JavaScriptRepresentable... arguments);
    
    void releaseProxy(String proxyId);
}

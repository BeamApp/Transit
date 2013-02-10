package com.getbeamapp.transit;

public interface TransitAdapter {
    public void initialize();
    public TransitProxy evaluate(String stringToEvaluate);
}

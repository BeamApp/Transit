package com.getbeamapp.transit;

public abstract class TransitEvaluatable extends TransitObject {
    
    public Object eval(String stringToEvaluate, Object... values) {
        return evalWithThisArg(stringToEvaluate, null, values);
    }

    public abstract Object evalWithThisArg(String stringToEvaluate, Object thisArg, Object... values);
    
    public abstract void evalWithThisArgAsync(String stringToEvaluate, Object thisArg, Object... values);
}

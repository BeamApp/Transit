package com.getbeamapp.transit;

public abstract class TransitEvaluatable extends TransitObject {
    
    public Object eval(String stringToEvaluate, Object... arguments) {
        return evalWithThisArg(stringToEvaluate, null, arguments);
    }

    public abstract Object evalWithThisArg(String stringToEvaluate, Object thisArg, Object... arguments);
    
}

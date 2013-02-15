package com.getbeamapp.transit;

public abstract class TransitEvaluatable extends TransitObject {
    public Object eval(String stringToEvaluate) {
        return eval(stringToEvaluate, new Object[0]);
    }

    public Object eval(String stringToEvaluate, Object... arguments) {
        return evalWithContext(stringToEvaluate, this, arguments);
    }

    public Object evalWithContext(String stringToEvaluate, Object context) {
        return evalWithContext(stringToEvaluate, context, new Object[0]);
    }

    public abstract Object evalWithContext(String stringToEvaluate, Object thisArg, Object... arguments);
}

package com.getbeamapp.transit;

import java.util.HashMap;
import java.util.Map;

public abstract class TransitContext extends TransitProxy {

    public TransitContext() {
        super(null, null);
        this.rootContext = this;
    }

    @Override
    public abstract Object evalWithContext(String stringToEvaluate, Object context, Object... arguments);

    private final Map<String, TransitNativeFunction> retrainedNativeFunctions = new HashMap<String, TransitNativeFunction>();

    private long _nextNativeId = 0;

    private String nextNativeId() {
        return String.valueOf(_nextNativeId++);
    }

    public TransitNativeFunction getCallback(String string) {
        return retrainedNativeFunctions.get(string);
    }

    protected void retainNativeFunction(TransitNativeFunction function) {
        retrainedNativeFunctions.put(function.getNativeId(), function);
    }

    public TransitNativeFunction registerCallable(TransitCallable callable) {
        TransitNativeFunction function = new TransitNativeFunction(this, callable, nextNativeId());
        retainNativeFunction(function);
        return function;
    }

    public abstract void releaseProxy(String id);

    public String jsExpressionFromCode(String stringToEvaluate, Object... arguments) {
        return jsExpressionFromCodeWithThis(stringToEvaluate, null, arguments);
    }

    public String jsExpressionFromCodeWithThis(String stringToEvaluate, Object thisArg, Object... arguments) {
        TransitScriptBuilder builder = new TransitScriptBuilder("transit", thisArg);
        builder.process(stringToEvaluate, arguments);
        return builder.toScript();
    }

    public String convertObjectToExpression(Object o) {
        return jsExpressionFromCode("@", o);
    }

}

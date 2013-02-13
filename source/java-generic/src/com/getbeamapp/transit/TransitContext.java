package com.getbeamapp.transit;

import java.util.HashMap;
import java.util.Map;

public abstract class TransitContext extends TransitProxy {

    public TransitContext() {
        super(null);
        this.rootContext = this;
    }

    @Override
    public abstract TransitProxy evalWithContext(String stringToEvaluate, Object context, Object... arguments);

    private final Map<String, TransitNativeFunction> callbacks = new HashMap<String, TransitNativeFunction>();

    private long _nextNativeId = 0;

    public String nextNativeId() {
        return String.valueOf(_nextNativeId++);
    }

    public TransitNativeFunction getCallback(String string) {
        return callbacks.get(string);
    }

    public TransitNativeFunction registerCallable(TransitCallable callable) {
        String nativeId = nextNativeId();
        TransitNativeFunction function = new TransitNativeFunction(this, callable, nativeId);
        callbacks.put(nativeId, function);
        return function;
    }

    public abstract void releaseProxy(String id);

}

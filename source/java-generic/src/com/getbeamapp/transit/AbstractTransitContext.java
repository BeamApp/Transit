package com.getbeamapp.transit;

import java.util.HashMap;
import java.util.Map;

public abstract class AbstractTransitContext extends TransitProxy {

    public AbstractTransitContext() {
        super(null);
        this.rootContext = this;
    }

    @Override
    public abstract TransitProxy eval(String stringToEvaluate, TransitProxy context, Object... arguments);

    private final Map<String, TransitNativeFunction> callbacks = new HashMap<String, TransitNativeFunction>();

    private long _nextNativeId = 0;

    public String nextNativeId() {
        return String.valueOf(_nextNativeId++);
    }

    public TransitNativeFunction getCallback(String string) {
        return callbacks.get(string);
    }

}

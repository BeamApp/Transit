package com.getbeamapp.transit;

public abstract class TransitFunction extends TransitProxy {
    
    public TransitFunction(TransitContext rootContext, String proxyId) {
        super(rootContext, proxyId);
    }

    public final Object call() {
        return call(null, new Object[0]);
    }

    public final Object call(Object... arguments) {
        return call(null, arguments);
    }

    public abstract Object call(Object context, Object... arguments);
}

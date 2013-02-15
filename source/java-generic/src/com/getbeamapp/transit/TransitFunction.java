package com.getbeamapp.transit;

public abstract class TransitFunction extends TransitProxy {
    
    public TransitFunction(TransitContext rootContext, String proxyId) {
        super(rootContext, proxyId);
    }

    public final Object call(Object... arguments) {
        return callWithThisArg(null, arguments);
    }

    public abstract Object callWithThisArg(Object thisArg, Object... arguments);
}

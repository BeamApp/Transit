package com.getbeamapp.transit.common;


public abstract class TransitFunction extends TransitProxy {
    
    public TransitFunction(TransitContext rootContext, String proxyId) {
        super(rootContext, proxyId);
    }

    public final Object call(Object... arguments) {
        return callWithThisArg(null, arguments);
    }
    
    public final void callAsync(Object... arguments) {
        callWithThisArgAsync(null, arguments);
    }

    public abstract Object callWithThisArg(Object thisArg, Object... arguments);
    
    public abstract void callWithThisArgAsync(Object thisArg, Object... arguments);
}

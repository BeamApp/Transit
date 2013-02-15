package com.getbeamapp.transit;

public class TransitNativeFunction extends TransitFunction {

    private final TransitCallable implementation;

    TransitNativeFunction(TransitContext rootContext, TransitCallable callable, String nativeId) {
        super(rootContext, nativeId);
        this.implementation = callable;
        assert (nativeId != null);
    }

    public String getNativeId() {
        return getProxyId();
    }

    @Override
    public Object call(Object thisArg, Object... arguments) {
        if (thisArg == null) {
            thisArg = getRootContext();
        }

        return implementation.evaluate(thisArg, arguments);
    }

}

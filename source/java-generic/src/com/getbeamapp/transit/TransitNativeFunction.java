package com.getbeamapp.transit;

public class TransitNativeFunction extends TransitFunction implements JavaScriptRepresentable {

    private final String nativeId;

    private final TransitCallable implementation;

    TransitNativeFunction(AbstractTransitContext rootContext, TransitCallable callable, String nativeId) {
        super(rootContext);
        this.nativeId = nativeId;
        this.implementation = callable;
        assert (nativeId != null);
    }
    
    public String getNativeId() {
        return nativeId;
    }

    @Override
    public Object call(Object thisArg, Object... arguments) {
        return implementation.evaluate(thisArg, arguments);
    }

    @Override
    public String getJavaScriptRepresentation() {
        return "transit.nativeFunction(\"" + nativeId + "\")";
    }

}

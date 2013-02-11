package com.getbeamapp.transit;

public class TransitNativeFunction extends TransitFunction implements JavaScriptRepresentable {

    private final String nativeId;

    private final TransitCallable implementation;

    public TransitNativeFunction(AbstractTransitContext rootContext, TransitCallable callable) {
        super(rootContext);
        this.nativeId = rootContext.nextNativeId();
        this.implementation = callable;
        assert (nativeId != null);
    }

    TransitNativeFunction(AbstractTransitContext rootContext, TransitCallable callable, String nativeId) {
        super(rootContext);
        this.nativeId = nativeId;
        this.implementation = callable;
        assert (nativeId != null);
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

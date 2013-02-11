package com.getbeamapp.transit;

import java.util.Arrays;

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
        TransitProxy[] convertedArguments = TransitProxy.convertArray(rootContext, Arrays.asList(arguments)).toArray(new TransitProxy[0]);
        return implementation.evaluate(TransitProxy.withValue(rootContext, thisArg), convertedArguments);
    }

    @Override
    public String getJavaScriptRepresentation() {
        return "transit.nativeFunction(\"" + nativeId + "\")";
    }

}

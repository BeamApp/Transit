package com.getbeamapp.transit;

import java.util.Arrays;

public class TransitNativeFunction extends TransitFunction implements JSRepresentable {

    private final String nativeId;

    private final TransitCallable implementation;

    TransitNativeFunction(TransitContext rootContext, TransitCallable callable, String nativeId) {
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
        return call(rootContext.proxify(thisArg), convertedArguments);
    }
    
    public Object call(TransitProxy thisArg, TransitProxy... arguments) {
        if(thisArg == null) {
            thisArg = rootContext;
        }
        
        return implementation.evaluate(thisArg, arguments);
    }

    @Override
    public String getJSRepresentation() {
        return "transit.nativeFunction(\"" + nativeId + "\")";
    }
    
    @Override
    public String toString() {
        return String.format("[%s nativeId:%s]", this.getClass().getSimpleName(), nativeId);
    }

}

package com.getbeamapp.transit.common;


public class TransitJSFunction extends TransitFunction {

    public TransitJSFunction(TransitContext rootContext, String proxyId) {
        super(rootContext, proxyId);
    }

    @Override
    public Object callWithThisArg(Object thisArg, Object... arguments) {
        boolean emptyArguments = arguments.length == 0;
        
        if (thisArg == null || thisArg == getContext()) {
            if (emptyArguments) {
                return getContext().eval("@()", this);
            } else {
                return getContext().eval("@(@)", this, TransitScriptBuilder.arguments(arguments));
            }
        } else if (emptyArguments) {
            return getContext().eval("@.call(@)", this, thisArg);
        } else {
            return getContext().eval("@.call(@, @)", this, thisArg, TransitScriptBuilder.arguments(arguments));
        }
    }

    @Override
    public void callWithThisArgAsync(Object thisArg, Object... arguments) {
        boolean emptyArguments = arguments.length == 0;
        
        if (thisArg == null || thisArg == getContext()) {
            if (emptyArguments) {
                getContext().evalAsync("@()", this);
            } else {
                getContext().evalAsync("@(@)", this, TransitScriptBuilder.arguments(arguments));
            }
        } else if (emptyArguments) {
            getContext().evalAsync("@.call(@)", this, thisArg);
        } else {
            getContext().evalAsync("@.call(@, @)", this, thisArg, TransitScriptBuilder.arguments(arguments));            
        }
    }

}

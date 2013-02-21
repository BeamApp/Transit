package com.getbeamapp.transit.common;


public class TransitJSFunction extends TransitFunction {

    public TransitJSFunction(TransitContext rootContext, String proxyId) {
        super(rootContext, proxyId);
    }

    @Override
    public Object callWithThisArg(Object thisArg, Object... arguments) {
        if (thisArg == null || thisArg == getContext()) {
            if (arguments.length == 0) {
                return getContext().eval("@()", this);
            } else {
                return getContext().eval("@(@)", this, TransitScriptBuilder.arguments(arguments));
            }
        } else {
            return getContext().eval("@.call(@, @)", this, thisArg, TransitScriptBuilder.arguments(arguments));
        }
    }

    @Override
    public void callWithThisArgAsync(Object thisArg, Object... arguments) {
        if (thisArg == null || thisArg == getContext()) {
            if (arguments.length == 0) {
                getContext().evalAsync("@()", this);
            } else {
                getContext().evalAsync("@(@)", this, TransitScriptBuilder.arguments(arguments));
            }
        } else {
            getContext().evalAsync("@.call(@, @)", this, thisArg, TransitScriptBuilder.arguments(arguments));
        }
    }

}

package com.getbeamapp.transit;

public class TransitJSFunction extends TransitFunction {

    public TransitJSFunction(TransitContext rootContext, String proxyId) {
        super(rootContext, proxyId);
    }

    @Override
    public Object callWithThisArg(Object thisArg, Object... arguments) {
        if (thisArg == null || thisArg == getContext()) {
            return getContext().eval("@(@)", this, TransitScriptBuilder.arguments(arguments));
        } else {
            return getContext().eval("@.apply(@, @)", this, thisArg, arguments);
        }
    }
    
    @Override
    public void callWithThisArgAsync(Object thisArg, Object... arguments) {
        if (thisArg == null || thisArg == getContext()) {
            getContext().evalAsync("@(@)", this, TransitScriptBuilder.arguments(arguments));
        } else {
            getContext().evalAsync("@.apply(@, @)", this, thisArg, arguments);
        }
    }

}

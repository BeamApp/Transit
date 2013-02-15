package com.getbeamapp.transit;


public class TransitProxy extends TransitObject {

    private final String proxyId;
    private final TransitContext context;

    TransitProxy(TransitContext context, String proxyId) {
        assert context != null;
        assert proxyId != null;
        
        this.context = context;
        this.proxyId = proxyId;
    }
    
    @Override
    public TransitContext getContext() {
        return context;
    }

    public Object eval(String stringToEvaluate) {
        return eval(stringToEvaluate, new Object[0]);
    }

    public Object eval(String stringToEvaluate, Object... arguments) {
        return evalWithContext(stringToEvaluate, this, arguments);
    }

    public Object evalWithContext(String stringToEvaluate, Object context) {
        return evalWithContext(stringToEvaluate, context, new Object[0]);
    }

    public Object evalWithContext(String stringToEvaluate, Object thisArg,
            Object... arguments) {
        return context.evalWithContext(stringToEvaluate, thisArg, arguments);
    }

    public String getProxyId() {
        return proxyId;
    }

    private boolean finalized = false;

    @Override
    protected void finalize() throws Throwable {
        if (!finalized) {
            if (this.context != null && proxyId != null) {
                this.context.releaseProxy(proxyId);
            }

            finalized = true;
        }

        super.finalize();
    }
}

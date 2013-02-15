package com.getbeamapp.transit;


public class TransitProxy extends TransitObject {

    private final String proxyId;
    private final TransitContext rootContext;

    TransitProxy(TransitContext rootContext, String proxyId) {
        assert rootContext != null;
        assert proxyId != null;
        
        this.rootContext = rootContext;
        this.proxyId = proxyId;
    }
    
    @Override
    public TransitContext getRootContext() {
        return rootContext;
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

    public Object evalWithContext(String stringToEvaluate, Object context,
            Object... arguments) {
        return rootContext.evalWithContext(stringToEvaluate, context, arguments);
    }

    public String getProxyId() {
        return proxyId;
    }

    private boolean finalized = false;

    @Override
    protected void finalize() throws Throwable {
        if (!finalized) {
            if (this.rootContext != null && proxyId != null) {
                this.rootContext.releaseProxy(proxyId);
            }

            finalized = true;
        }

        super.finalize();
    }
}

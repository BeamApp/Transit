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

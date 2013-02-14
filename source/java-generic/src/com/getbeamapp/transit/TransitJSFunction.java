package com.getbeamapp.transit;

import android.util.Log;

public class TransitJSFunction extends TransitFunction {

    private final String id;

    public TransitJSFunction(TransitContext rootContext, String id) {
        super(rootContext);
        this.id = id;
    }

    @Override
    public Object call(Object context, Object... arguments) {
        return null;
    }

    @Override
    protected void finalize() throws Throwable {
        Log.d("A", "HERE");
        this.rootContext.releaseProxy(id);
        super.finalize();
    }

    @Override
    public String getJSRepresentation() {
        return String.format("transit.r(\"%s\")", id);
    }

}

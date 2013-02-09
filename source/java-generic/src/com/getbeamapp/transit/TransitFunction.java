package com.getbeamapp.transit;

public abstract class TransitFunction extends TransitProxy {
    public TransitFunction(AbstractTransitContext rootContext) {
        super(rootContext);
    }

    public final TransitProxy call() {
        return call(null, new Object[0]);
    }

    public final TransitProxy call(Object... arguments) {
        return call(null, arguments);
    }

    public abstract TransitProxy call(TransitProxy context, Object... arguments);
}

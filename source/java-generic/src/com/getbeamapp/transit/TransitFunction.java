package com.getbeamapp.transit;

public abstract class TransitFunction extends TransitProxy {
    public TransitFunction(AbstractTransitContext rootContext) {
        super(rootContext);
    }

    public final Object call() {
        return call(null, new Object[0]);
    }

    public final Object call(Object... arguments) {
        return call(null, arguments);
    }

    public abstract Object call(Object context, Object... arguments);
}

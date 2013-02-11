package com.getbeamapp.transit;

public abstract class AbstractTransitContext extends TransitProxy {

    public AbstractTransitContext() {
        super(null);
        this.rootContext = this;
    }

    @Override
    public abstract TransitProxy eval(String stringToEvaluate, TransitProxy context, Object... arguments);

    private long _nextNativeId = 0;

    public String nextNativeId() {
        return String.valueOf(_nextNativeId++);
    }

}

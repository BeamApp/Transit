package com.getbeamapp.transit.prompt;

import com.getbeamapp.transit.TransitException;

class TransitExceptionAction extends TransitAction {
    private Throwable throwable;

    public TransitExceptionAction(String message) {
        this.throwable = new TransitException(message);
    }

    public TransitExceptionAction(Throwable e) {
        assert (e != null);
        this.throwable = e;
    }

    @Override
    public String getJavaScriptRepresentation() {
        return createJavaScriptRepresentation("EXCEPTION", throwable.toString());
    }
}

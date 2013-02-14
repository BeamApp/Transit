package com.getbeamapp.transit.prompt;

import com.getbeamapp.transit.TransitException;
import com.getbeamapp.transit.prompt.TransitChromeClient.TransitResponse;

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
    public String getJSRepresentation() {
        return createJavaScriptRepresentation(TransitResponse.EXCEPTION, throwable.toString());
    }
}

package com.getbeamapp.transit.android.prompt;

import com.getbeamapp.transit.android.prompt.TransitPromptAdapter.TransitResponse;
import com.getbeamapp.transit.common.TransitException;

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

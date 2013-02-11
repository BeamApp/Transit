package com.getbeamapp.transit.prompt;

import com.getbeamapp.transit.JavaScriptRepresentable;
import com.getbeamapp.transit.prompt.TransitChromeClient.TransitResponse;

class TransitReturnResultAction extends TransitAction {
    private JavaScriptRepresentable object;

    public TransitReturnResultAction(JavaScriptRepresentable o) {
        this.object = o;
    }
    
    @Override
    public String getJavaScriptRepresentation() {
        return createJavaScriptRepresentation(TransitResponse.RETURN, object);
    }
}

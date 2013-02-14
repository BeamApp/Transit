package com.getbeamapp.transit.prompt;

import com.getbeamapp.transit.JSRepresentable;
import com.getbeamapp.transit.prompt.TransitChromeClient.TransitResponse;

class TransitReturnResultAction extends TransitAction {
    private JSRepresentable object;

    public TransitReturnResultAction(JSRepresentable o) {
        this.object = o;
    }
    
    @Override
    public String getJSRepresentation() {
        return createJavaScriptRepresentation(TransitResponse.RETURN, object);
    }
}

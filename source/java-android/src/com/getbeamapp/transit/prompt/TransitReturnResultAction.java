package com.getbeamapp.transit.prompt;

import com.getbeamapp.transit.JavaScriptRepresentable;

class TransitReturnResultAction extends TransitAction {
    private JavaScriptRepresentable object;

    public TransitReturnResultAction(JavaScriptRepresentable o) {
        this.object = o;
    }
    
    @Override
    public String getJavaScriptRepresentation() {
        return createJavaScriptRepresentation("RETURN", object);
    }
}

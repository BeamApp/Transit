package com.getbeamapp.transit.android.prompt;

import com.getbeamapp.transit.android.prompt.TransitPromptAdapter.TransitResponse;
import com.getbeamapp.transit.common.JSRepresentable;

class TransitReturnResultAction extends TransitAction {
    private JSRepresentable expr;

    public TransitReturnResultAction(String s) {
        this.expr = new JSRepresentable.Expression(s);
    }

    @Override
    public String getJSRepresentation() {
        return createJavaScriptRepresentation(TransitResponse.RETURN, expr);
    }
}

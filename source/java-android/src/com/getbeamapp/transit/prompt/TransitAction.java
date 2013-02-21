package com.getbeamapp.transit.prompt;

import org.json.JSONObject;

import com.getbeamapp.transit.JSRepresentable;
import com.getbeamapp.transit.prompt.TransitPromptAdapter.TransitResponse;

public abstract class TransitAction implements JSRepresentable {
    protected String createJavaScriptRepresentation(TransitResponse type, JSRepresentable javaScriptRepresentation) {
        if (javaScriptRepresentation != null) {
            return createJavaScriptRepresentation(type, javaScriptRepresentation.getJSRepresentation());
        } else {
            return createJavaScriptRepresentation(type, "null");
        }
    }

    protected String createJavaScriptRepresentation(TransitResponse type, String data) {
        assert (type != null);
        return "{ \"type\": " + JSONObject.quote(type.getString()) + ", \"data\": " + JSONObject.quote(data) + " }";
    }
}

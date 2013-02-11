package com.getbeamapp.transit.prompt;

import org.json.JSONObject;

import com.getbeamapp.transit.JavaScriptRepresentable;
import com.getbeamapp.transit.prompt.TransitChromeClient.TransitResponse;

public abstract class TransitAction implements JavaScriptRepresentable {
    protected String createJavaScriptRepresentation(TransitResponse type, JavaScriptRepresentable javaScriptRepresentation) {
        if (javaScriptRepresentation != null) {
            return createJavaScriptRepresentation(type, javaScriptRepresentation.getJavaScriptRepresentation());
        } else {
            return createJavaScriptRepresentation(type, "null");
        }
    }

    protected String createJavaScriptRepresentation(TransitResponse type, String data) {
        assert (type != null);
        return "{ \"type\": " + JSONObject.quote(type.getString()) + ", \"data\": " + JSONObject.quote(data) + " }";
    }
}

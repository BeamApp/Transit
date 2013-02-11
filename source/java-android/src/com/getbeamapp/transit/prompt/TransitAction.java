package com.getbeamapp.transit.prompt;

import org.json.JSONObject;

import com.getbeamapp.transit.JavaScriptRepresentable;

public abstract class TransitAction implements JavaScriptRepresentable {
    protected String createJavaScriptRepresentation(String type, String data) {
        return "{ \"type\": " + JSONObject.quote(type) + ", \"data\": " + JSONObject.quote(data) + " }";
    }
}

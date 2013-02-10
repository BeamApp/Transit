package com.getbeamapp.transit.prompt;

import org.json.JSONObject;

import com.getbeamapp.transit.TransitProxy;

import android.os.ConditionVariable;

class TransitEvalAction extends TransitAction {
    public String stringToEvaluate;

    public final ConditionVariable lock = new ConditionVariable();

    public TransitProxy result;

    public RuntimeException exception;

    public TransitEvalAction(String stringToEvaluate) {
        this.stringToEvaluate = stringToEvaluate;
    }

    public String getStringToEvaluate() {
        return stringToEvaluate;
    }

    @Override
    public String toJavaScript() {
        return "{ \"type\": \"EVAL\", \"data\": "
                + JSONObject.quote(stringToEvaluate) + " }";
    }
}

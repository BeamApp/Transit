package com.getbeamapp.transit.prompt;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.getbeamapp.transit.JavaScriptRepresentable;
import com.getbeamapp.transit.TransitContext;
import com.getbeamapp.transit.TransitException;
import com.getbeamapp.transit.TransitProxy;
import com.getbeamapp.transit.prompt.TransitChromeClient.TransitResponse;

import android.os.ConditionVariable;

class TransitEvalAction extends TransitAction {
    private final String stringToEvaluate;

    private final ConditionVariable lock = new ConditionVariable();

    private TransitProxy result;

    private TransitException exception;

    private final JavaScriptRepresentable thisArg;

    private final JavaScriptRepresentable[] arguments;

    private final TransitContext context;

    public TransitEvalAction(TransitContext context, String stringToEvaluate, JavaScriptRepresentable thisArg, JavaScriptRepresentable[] arguments) {
        this.context = context;
        this.stringToEvaluate = stringToEvaluate;
        this.thisArg = thisArg;
        this.arguments = arguments;
    }

    public String getStringToEvaluate() {
        return stringToEvaluate;
    }

    public void resolve() {
        resolveWith(null);
    }

    public void resolveWith(Object result) {
        if (result == null) {
            this.result = null;
        } else if (result instanceof TransitProxy) {
            this.result = (TransitProxy) result;
        } else {
            this.result = context.proxify(result);
        }

        lock.open();
    }

    public void reject() {
        rejectWith(new TransitException("Rejected"));
    }

    public void rejectWith(String errorMessage) {
        rejectWith(new TransitException(errorMessage));
    }

    public void rejectWith(Throwable throwable) {
        if (throwable instanceof TransitException) {
            this.exception = (TransitException) throwable;
        } else {
            this.exception = new TransitException(throwable);
        }

        lock.open();
    }

    public TransitProxy block() {
        lock.block();
        return afterBlock();
    }

    public TransitProxy block(long timeout) {
        if (lock.block(timeout)) {
            return afterBlock();
        } else {
            throw new TransitException("Timeout");
        }
    }

    private TransitProxy afterBlock() {
        if (exception != null) {
            throw exception;
        } else {
            return result;
        }
    }

    @Override
    public String getJavaScriptRepresentation() {
        try {
            JSONObject result = new JSONObject();
            result.put("type", TransitResponse.EVAL);
            result.put("script", context.jsExpressionFromCode(stringToEvaluate, (Object[]) this.arguments));
            result.put("thisArg", thisArg.getJavaScriptRepresentation());

            JSONArray serializedArguments = new JSONArray();
            for (JavaScriptRepresentable argument : this.arguments) {
                serializedArguments.put(argument.getJavaScriptRepresentation());
            }

            result.put("arguments", serializedArguments.toString());
            return result.toString();
        } catch (JSONException e) {
            throw new TransitException(e);
        }
    }
}

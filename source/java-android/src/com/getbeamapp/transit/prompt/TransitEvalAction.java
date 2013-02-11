package com.getbeamapp.transit.prompt;

import org.json.JSONObject;

import com.getbeamapp.transit.TransitException;
import com.getbeamapp.transit.TransitProxy;

import android.os.ConditionVariable;

class TransitEvalAction extends TransitAction {
    private final String stringToEvaluate;

    private final ConditionVariable lock = new ConditionVariable();

    private TransitProxy result;

    private TransitException exception;

    public TransitEvalAction(String stringToEvaluate) {
        this.stringToEvaluate = stringToEvaluate;
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
            // TODO: set context
            this.result = TransitProxy.withValue(null, result);
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
        return "{ \"type\": \"EVAL\", \"data\": "
                + JSONObject.quote(stringToEvaluate) + " }";
    }
}

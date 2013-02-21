package com.getbeamapp.transit.android.prompt;

import android.os.ConditionVariable;

import com.getbeamapp.transit.TransitException;
import com.getbeamapp.transit.android.prompt.TransitPromptAdapter.TransitResponse;

class TransitEvalAction extends TransitAction {
    private final String stringToEvaluate;

    private final ConditionVariable lock = new ConditionVariable();

    private Object result;

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
        this.result = result;
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

    public Object block() {
        lock.block();
        return afterBlock();
    }

    private Object afterBlock() {
        if (exception != null) {
            throw exception;
        } else {
            return result;
        }
    }

    @Override
    public String getJSRepresentation() {
        return createJavaScriptRepresentation(TransitResponse.EVAL, stringToEvaluate);
    }
}

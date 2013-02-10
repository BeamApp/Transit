package com.getbeamapp.transit.prompt;

class TransitExceptionAction extends TransitAction {
    private Exception exception;

    public TransitExceptionAction(Exception e) {
        this.exception = e;
    }
}

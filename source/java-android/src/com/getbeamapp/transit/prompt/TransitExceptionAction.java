package com.getbeamapp.transit.prompt;

class TransitExceptionAction extends TransitAction {
    private Exception exception;

    public TransitExceptionAction(Exception e) {
        assert (e != null);
        this.exception = e;
    }

    @Override
    public String getJavaScriptRepresentation() {
        return createJavaScriptRepresentation("EXCEPTION", exception.getMessage());
    }
}

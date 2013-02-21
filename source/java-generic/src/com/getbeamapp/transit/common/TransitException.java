package com.getbeamapp.transit.common;

public class TransitException extends RuntimeException {

    private static final long serialVersionUID = 2488242118762127818L;

    public TransitException(String message) {
        super(message);
    }

    public TransitException(Throwable throwable) {
        super(throwable);
    }

    public TransitException(String message, Throwable throwable) {
        super(message, throwable);
    }

}

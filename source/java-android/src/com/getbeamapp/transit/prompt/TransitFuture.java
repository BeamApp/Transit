package com.getbeamapp.transit.prompt;

import android.os.ConditionVariable;

public class TransitFuture<T> {
    private T result;

    private ConditionVariable lock = new ConditionVariable(false);

    public void resolve() {
        resolve(null);
    }

    public void resolve(T o) {
        result = o;
        lock.open();
    }

    public T block() {
        lock.block();
        return result;
    }
}

package com.getbeamapp.transit;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

import android.os.ConditionVariable;

public class MockCallable implements TransitCallable {

    private long callCount = 0;
    private final ConditionVariable lock = new ConditionVariable(false);
    private final List<Object> arguments = new LinkedList<Object>();
    private final Object result;
    private final RuntimeException throwable;

    public MockCallable() {
        this.result = null;
        this.throwable = null;
    }

    public MockCallable(Object result) {
        this.result = result;
        this.throwable = null;
    }

    public MockCallable(RuntimeException throwable) {
        this.throwable = throwable;
        this.result = null;
    }

    @Override
    public Object evaluate(Object thisArg, Object... arguments) {
        this.arguments.add(thisArg);
        this.arguments.addAll(Arrays.asList(arguments));

        try {
            if (throwable != null) {
                throw throwable;
            } else {
                return result;
            }
        } finally {
            callCount++;
            lock.open();
        }
    }

    public List<Object> block() {
        lock.block();
        return arguments;
    }

    public boolean isCalled() {
        return callCount > 0;
    }

    public long getCallCount() {
        return callCount;
    }

    public void reset() {
        callCount = 0;
        lock.close();
        arguments.clear();
    }
}

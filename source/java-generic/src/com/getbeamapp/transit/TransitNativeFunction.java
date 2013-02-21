package com.getbeamapp.transit;

import java.util.EnumSet;

import com.getbeamapp.transit.TransitCallable.Flags;

public class TransitNativeFunction extends TransitFunction {

    private long callCount = 0;

    private final TransitCallable implementation;

    private EnumSet<Flags> flags;

    TransitNativeFunction(TransitContext rootContext, TransitCallable callable, EnumSet<Flags> flags, String nativeId) {
        super(rootContext, nativeId);
        this.implementation = callable;
        this.flags = flags;
        assert (nativeId != null);
    }

    public String getNativeId() {
        return getProxyId();
    }

    public TransitJSObject getJSOptions() {

        if (flags.isEmpty()) {
            return null;
        }

        TransitJSObject o = new TransitJSObject();

        if (flags.contains(Flags.ASYNC)) {
            o.put("async", true);
        }

        if (flags.contains(Flags.NO_THIS)) {
            o.put("noThis", true);
        }

        return o;
    }

    @Override
    public Object callWithThisArg(Object thisArg, Object... arguments) {
        if (thisArg == null) {
            thisArg = getContext();
        }

        try {
            return implementation.evaluate(thisArg, arguments);
        } finally {
            callCount++;
        }
    }
    
    @Override
    public void callWithThisArgAsync(final Object thisArg, final Object... arguments) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    callWithThisArg(thisArg, arguments);
                } catch (Exception e) {
                    // REVIEW: is it okay to just ignore?
                }
            }
        }).run();
    }
    
    public long getCallCount() {
        return callCount;
    }

}

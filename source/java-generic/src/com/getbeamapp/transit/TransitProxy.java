package com.getbeamapp.transit;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class TransitProxy {

    protected TransitContext rootContext;

    private String proxyId;

    TransitProxy(TransitContext rootContext, String proxyId) {
        this.rootContext = rootContext;
        this.proxyId = proxyId;
    }

    public TransitContext getRootContext() {
        return rootContext;
    }

    public static final Pattern NATIVE_FUNCTION_PATTERN = Pattern.compile("^__TRANSIT_NATIVE_FUNCTION_(.+)$");

    public static final Pattern JS_FUNCTION_PATTERN = Pattern.compile("^__TRANSIT_JS_FUNCTION_(.+)$");

    private static Object proxifyString(TransitContext context, String value) {
        Matcher nativeFunctionMatcher = NATIVE_FUNCTION_PATTERN.matcher(value);

        if (nativeFunctionMatcher.matches()) {
            TransitNativeFunction callback = context.getCallback(nativeFunctionMatcher.group(1));
            assert (callback != null);
            return callback;
        }

        Matcher jsFunctionMatcher = JS_FUNCTION_PATTERN.matcher(value);

        if (jsFunctionMatcher.matches()) {
            return new TransitJSFunction(context, jsFunctionMatcher.group(1));
        }

        return value;
    }

    public static TransitJSObject proxifyMap(TransitContext context, Map<?, ?> input) {
        TransitJSObject output = new TransitJSObject();

        for (Object keyObject : input.keySet()) {
            output.put(String.valueOf(keyObject), context.proxify(input.get(keyObject)));
        }

        return output;
    }

    public static TransitJSArray proxifyIterable(TransitContext context, Iterable<?> input) {
        TransitJSArray output = new TransitJSArray();

        for (Object o : input) {
            output.add(context.proxify(o));
        }

        return output;
    }

    public Object proxify(Object value) {
        if (value instanceof TransitProxy) {
            assert ((TransitProxy) value).getRootContext() == this;
            return value;
        } else if (value instanceof String) {
            return proxifyString(rootContext, (String) value);
        } else if (value instanceof Object[]) {
            return proxifyIterable(rootContext, Arrays.asList((Object[]) value));
        } else if (value instanceof List<?>) {
            return proxifyIterable(rootContext, (List<?>) value);
        } else if (value instanceof Map<?, ?>) {
            return proxifyMap(rootContext, (Map<?, ?>) value);
        } else {
            return value;
        }
    }

    public Object eval(String stringToEvaluate) {
        return eval(stringToEvaluate, new Object[0]);
    }

    public Object eval(String stringToEvaluate, Object... arguments) {
        return evalWithContext(stringToEvaluate, this, arguments);
    }

    public Object evalWithContext(String stringToEvaluate, Object context) {
        return evalWithContext(stringToEvaluate, context, new Object[0]);
    }

    public Object evalWithContext(String stringToEvaluate, Object context,
            Object... arguments) {
        return rootContext.eval(stringToEvaluate, context, arguments);
    }

    public String getProxyId() {
        return proxyId;
    }

    private boolean finalized = false;

    @Override
    protected void finalize() throws Throwable {
        if (!finalized) {
            if (this.rootContext != null && proxyId != null) {
                this.rootContext.releaseProxy(proxyId);
            }

            finalized = true;
        }

        super.finalize();
    }
}

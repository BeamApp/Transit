package com.getbeamapp.transit;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public abstract class TransitContext extends TransitEvaluatable {

    public abstract Object evalWithContext(String stringToEvaluate, Object context, Object... arguments);
    
    public abstract void releaseProxy(String id);

    private final Map<String, TransitNativeFunction> retrainedNativeFunctions = new HashMap<String, TransitNativeFunction>();

    private long _nextNativeId = 0;

    private static final Pattern NATIVE_FUNCTION_PATTERN = Pattern.compile("^__TRANSIT_NATIVE_FUNCTION_(.+)$");

    private static final Pattern JS_FUNCTION_PATTERN = Pattern.compile("^__TRANSIT_JS_FUNCTION_(.+)$");

    private String nextNativeId() {
        return String.valueOf(_nextNativeId++);
    }
    
    @Override
    public TransitContext getRootContext() {
        return this;
    }

    public TransitNativeFunction getCallback(String string) {
        return retrainedNativeFunctions.get(string);
    }

    protected void retainNativeFunction(TransitNativeFunction function) {
        retrainedNativeFunctions.put(function.getNativeId(), function);
    }

    public TransitNativeFunction registerCallable(TransitCallable callable) {
        TransitNativeFunction function = new TransitNativeFunction(this, callable, nextNativeId());
        retainNativeFunction(function);
        return function;
    }

    public Object eval(String stringToEvaluate, Object... arguments) {
        return evalWithContext(stringToEvaluate, null, arguments);
    }
    
    String jsExpressionFromCode(String stringToEvaluate, Object... arguments) {
        return jsExpressionFromCodeWithThis(stringToEvaluate, null, arguments);
    }

    String jsExpressionFromCodeWithThis(String stringToEvaluate, Object thisArg, Object... arguments) {
        TransitScriptBuilder builder = new TransitScriptBuilder("transit", thisArg);
        builder.process(stringToEvaluate, arguments);
        return builder.toScript();
    }

    public String convertObjectToExpression(Object o) {
        return jsExpressionFromCode("@", o);
    }

    private Object proxifyString(String value) {
        Matcher nativeFunctionMatcher = NATIVE_FUNCTION_PATTERN.matcher(value);

        if (nativeFunctionMatcher.matches()) {
            TransitNativeFunction callback = getCallback(nativeFunctionMatcher.group(1));
            assert (callback != null);
            return callback;
        }

        Matcher jsFunctionMatcher = JS_FUNCTION_PATTERN.matcher(value);

        if (jsFunctionMatcher.matches()) {
            return new TransitJSFunction(this, jsFunctionMatcher.group(1));
        }

        return value;
    }

    private TransitJSObject proxifyMap(Map<?, ?> input) {
        TransitJSObject output = new TransitJSObject();

        for (Object keyObject : input.keySet()) {
            output.put(String.valueOf(keyObject), proxify(input.get(keyObject)));
        }

        return output;
    }

    private TransitJSArray proxifyIterable(Iterable<?> input) {
        TransitJSArray output = new TransitJSArray();

        for (Object o : input) {
            output.add(proxify(o));
        }

        return output;
    }

    public Object proxify(Object value) {
        if (value instanceof TransitProxy) {
            assert ((TransitProxy) value).getRootContext() == this;
            return value;
        } else if (value instanceof TransitContext) {
            assert ((TransitContext) value) == this;
            return value;
        } else if (value instanceof String) {
            return proxifyString((String) value);
        } else if (value instanceof Object[]) {
            return proxifyIterable(Arrays.asList((Object[]) value));
        } else if (value instanceof List<?>) {
            return proxifyIterable((List<?>) value);
        } else if (value instanceof Map<?, ?>) {
            return proxifyMap((Map<?, ?>) value);
        } else {
            return value;
        }
    }

}

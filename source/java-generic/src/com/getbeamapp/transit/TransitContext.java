package com.getbeamapp.transit;

import java.util.Arrays;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public abstract class TransitContext extends TransitEvaluatable {

    public abstract void releaseProxy(String id);

    private final Map<String, TransitNativeFunction> retrainedNativeFunctions = new HashMap<String, TransitNativeFunction>();

    private long _nextNativeId = 0;

    private static final String NATIVE_FUNCTION_PREFIX = "__TRANSIT_NATIVE_FUNCTION_";

    private static final String JS_FUNCTION_PREFIX = "__TRANSIT_JS_FUNCTION_";

    private static final String GLOBAL_OBJECT = "__TRANSIT_OBJECT_GLOBAL";

    private String nextNativeId() {
        return String.valueOf(_nextNativeId++);
    }

    @Override
    public TransitContext getContext() {
        return this;
    }

    public TransitNativeFunction getCallback(String nativeId) {
        TransitNativeFunction f = retrainedNativeFunctions.get(nativeId);

        if (f == null) {
            throw new IllegalArgumentException(String.format("No function found for native ID `%s`", nativeId));
        }

        return f;
    }

    protected void retainNativeFunction(TransitNativeFunction function) {
        retrainedNativeFunctions.put(function.getNativeId(), function);
    }

    public TransitNativeFunction registerCallable(TransitCallable callable) {
        return registerCallable(callable, EnumSet.noneOf(TransitCallable.Flags.class));
    }

    public TransitNativeFunction registerCallable(TransitCallable callable, EnumSet<TransitCallable.Flags> flags) {
        TransitNativeFunction function = new TransitNativeFunction(this, callable, flags, nextNativeId());
        retainNativeFunction(function);
        return function;
    }

    public Object eval(String stringToEvaluate, Object... values) {
        return evalWithThisArg(stringToEvaluate, null, values);
    }

    public void evalAsync(String stringToEvaluate, Object... values) {
        evalWithThisArgAsync(stringToEvaluate, null, values);
    }

    String jsExpressionFromCode(String stringToEvaluate, Object... values) {
        return jsExpressionFromCodeWithThis(stringToEvaluate, null, values);
    }

    String jsExpressionFromCodeWithThis(String stringToEvaluate, Object thisArg, Object... values) {
        TransitScriptBuilder builder = new TransitScriptBuilder("transit", thisArg);
        builder.process(stringToEvaluate, values);
        return builder.toScript();
    }

    public String convertObjectToExpression(Object o) {
        return jsExpressionFromCode("@", o);
    }

    Object proxifyString(String value) {
        if (value == null || !value.startsWith("__T")) {
            return value;
        } else if (value.equals(GLOBAL_OBJECT)) {
            return this;
        } else if (value.startsWith(NATIVE_FUNCTION_PREFIX)) {
            return getCallback(value.substring(NATIVE_FUNCTION_PREFIX.length()));
        } else if (value.startsWith(JS_FUNCTION_PREFIX)) {
            return new TransitJSFunction(this, value.substring(JS_FUNCTION_PREFIX.length()));
        } else {
            return value;
        }
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
            assert ((TransitProxy) value).getContext() == this;
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

    public Object invoke(TransitJSObject invocationDescription) {
        return prepareInvoke(invocationDescription).invoke();
    }

    public PreparedInvocation prepareInvoke(TransitJSObject invocationDescription) {
        final String nativeId = invocationDescription.get("nativeId").toString();
        final Object thisArg = invocationDescription.get("thisArg");
        final Object[] arguments = invocationDescription.getArray("args").toArray(new Object[0]);
        final TransitNativeFunction callback = getCallback(nativeId);

        return new PreparedInvocation() {
            @Override
            public Object invoke() {
                return callback.callWithThisArg(thisArg, arguments);
            }

            @Override
            public TransitFunction getFunction() {
                return callback;
            }
        };
    }

    public interface PreparedInvocation {
        Object invoke();

        TransitFunction getFunction();
    }

}

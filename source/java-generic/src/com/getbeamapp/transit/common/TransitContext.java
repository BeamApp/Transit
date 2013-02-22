package com.getbeamapp.transit.common;

import java.io.IOException;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonToken;

public abstract class TransitContext extends TransitEvaluatable {

    public abstract void releaseProxy(String id);

    private final Map<String, TransitNativeFunction> retrainedNativeFunctions = new HashMap<String, TransitNativeFunction>();

    private long _nextNativeId = 0;

    private final JsonFactory jsonFactory;

    private static final String NATIVE_FUNCTION_PREFIX = "__TRANSIT_NATIVE_FUNCTION_";

    private static final String JS_FUNCTION_PREFIX = "__TRANSIT_JS_FUNCTION_";

    private static final String GLOBAL_OBJECT = "__TRANSIT_OBJECT_GLOBAL";

    public TransitContext() {
        this.jsonFactory = new JsonFactory();
    }

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

    public void replaceFunction(String location, final TransitReplacementCallable callable) {
        final TransitJSFunction original = (TransitJSFunction) eval(location);

        TransitNativeFunction f = registerCallable(new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                return callable.evaluate(original, thisArg, arguments);
            }
        });

        eval("@ = @", TransitScriptBuilder.raw(location), f);
    }

    public void replaceFunctionAsync(String location, final TransitReplacementCallable callable) {
        TransitNativeFunction f = registerCallable(new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                TransitJSFunction original = (TransitJSFunction) arguments[0];
                Object[] rest = new Object[arguments.length - 1];

                for (int i = 1; i < arguments.length; i++) {
                    rest[i - 1] = arguments[i];
                }

                return callable.evaluate(original, thisArg, rest);
            }
        });

        Object locationExpression = TransitScriptBuilder.raw(location);

        evalAsync("(function(original, replacement) { @ = function() { return replacement.apply(this, [original].concat(Array.prototype.slice.call(arguments, 0))); } })(@, @)", locationExpression, locationExpression, f);
    }

    public Object eval(String stringToEvaluate, Object... values) {
        return evalWithThisArg(stringToEvaluate, null, values);
    }

    public void evalAsync(String stringToEvaluate, Object... values) {
        evalWithThisArgAsync(stringToEvaluate, null, values);
    }

    public String jsExpressionFromCode(String stringToEvaluate, Object... values) {
        return jsExpressionFromCodeWithThis(stringToEvaluate, null, values);
    }

    public String jsExpressionFromCodeWithThis(String stringToEvaluate, Object thisArg, Object... values) {
        TransitScriptBuilder builder = new TransitScriptBuilder("transit", thisArg);
        builder.process(stringToEvaluate, values);
        return builder.toScript();
    }

    public String convertObjectToExpression(Object o) {
        return jsExpressionFromCode("@", o);
    }

    private Object proxifyString(String value) {
        if (value == null || !value.startsWith("__T")) {
            return value;
        } else if (value.equals(GLOBAL_OBJECT)) {
            return this;
        } else if (value.startsWith(NATIVE_FUNCTION_PREFIX)) {
            return getCallback(value.substring(NATIVE_FUNCTION_PREFIX.length()));
        } else if (value.startsWith(JS_FUNCTION_PREFIX)) {
            return new TransitJSFunction(this, value);
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

    public Object parse(String json) {
        if (json == null) {
            return null;
        }

        try {
            JsonParser parser = jsonFactory.createParser(json);
            return unmarshal(parser, parser.nextToken());
        } catch (JsonParseException e) {
            throw new TransitException(json);
        } catch (IOException e) {
            throw new TransitException(json);
        }
    }

    public Iterable<Object> lazyParse(final String json) {
        return new Iterable<Object>() {
            @Override
            public Iterator<Object> iterator() {
                try {
                    final JsonParser parser = jsonFactory.createParser(json);

                    JsonToken arrayStartToken = parser.nextToken();
                    assert arrayStartToken == JsonToken.START_ARRAY;

                    final JsonToken firstToken = parser.nextToken();

                    return new Iterator<Object>() {

                        private JsonToken token = firstToken;
                        private boolean hasNext = (firstToken != JsonToken.END_ARRAY);

                        @Override
                        public void remove() {
                            // unsupported
                        }

                        @Override
                        public Object next() {
                            try {
                                Object result = unmarshal(parser, token);
                                token = parser.nextToken();
                                this.hasNext = (token != JsonToken.END_ARRAY);
                                return result;
                            } catch (IOException e) {
                                throw new TransitException(e);
                            }
                        }

                        @Override
                        public boolean hasNext() {
                            return hasNext;
                        }

                    };
                } catch (IOException e) {
                    throw new TransitException(e);
                }
            }
        };
    }

    private final Object unmarshal(JsonParser parser, JsonToken token)
            throws JsonParseException, IOException {
        switch (token) {
        case START_ARRAY:
            return unmarshalArray(parser, new TransitJSArray());
        case START_OBJECT:
            return unmarshalObject(parser, new TransitJSObject());
        case VALUE_FALSE:
            return Boolean.FALSE;
        case VALUE_TRUE:
            return Boolean.TRUE;
        case VALUE_NULL:
            return null;
        case VALUE_STRING:
            return proxifyString(parser.getText());
        case VALUE_NUMBER_FLOAT:
            return parser.getFloatValue();
        case VALUE_NUMBER_INT:
            return parser.getIntValue();
        default:
            throw new JsonParseException("Unexpected token", parser.getTokenLocation());
        }
    }

    private Object unmarshalObject(JsonParser parser, TransitJSObject object)
            throws JsonParseException, IOException {
        JsonToken token = parser.nextToken();

        while (token != JsonToken.END_OBJECT) {
            assert token == JsonToken.FIELD_NAME;
            String key = parser.getCurrentName();
            Object value = unmarshal(parser, parser.nextToken());
            object.put(key, value);
            token = parser.nextToken();
        }

        return object;
    }

    private Object unmarshalArray(JsonParser parser, TransitJSArray array)
            throws JsonParseException, IOException {
        JsonToken token = parser.nextToken();

        while (token != JsonToken.END_ARRAY) {
            array.add(unmarshal(parser, token));
            token = parser.nextToken();
        }

        return array;
    }

}

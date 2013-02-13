package com.getbeamapp.transit;

import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class TransitProxy implements JavaScriptRepresentable {
    public enum Type {
        UNKNOWN,
        NULL,
        BOOLEAN,
        NUMBER,
        STRING,
        ARRAY,
        OBJECT
    }

    protected Type type = Type.UNKNOWN;

    protected TransitContext rootContext;

    private Number numberValue;

    private Boolean booleanValue;

    private String stringValue;

    private List<TransitProxy> arrayValue;

    private Map<String, TransitProxy> objectValue;

    TransitProxy(TransitContext rootContext) {
        this.rootContext = rootContext;
    }

    public TransitContext getRootContext() {
        return rootContext;
    }

    public static final Pattern NATIVE_FUNCTION_PATTERN = Pattern.compile("^__TRANSIT_NATIVE_FUNCTION_(.+)$");

    public static final Pattern JS_FUNCTION_PATTERN = Pattern.compile("^__TRANSIT_JS_FUNCTION_(.+)$");

    private static TransitProxy createFromString(TransitContext context, String value) {
        Matcher nativeFunctionMatcher = NATIVE_FUNCTION_PATTERN.matcher(value);

        if (nativeFunctionMatcher.matches()) {
            TransitNativeFunction callback = context.getCallback(nativeFunctionMatcher.group(1));
            assert (callback != null);
            return callback;
        }

        Matcher jsFunctionMatcher = JS_FUNCTION_PATTERN.matcher(value);

        if (jsFunctionMatcher.matches()) {
            return new TransitJavaScriptFunction(context, jsFunctionMatcher.group(1));
        }

        TransitProxy result = new TransitProxy(context);
        result.type = Type.STRING;
        result.stringValue = value;
        return result;
    }

    public static Map<String, TransitProxy> convertMap(TransitContext context, Map<?, ?> input) {
        Map<String, TransitProxy> output = new HashMap<String, TransitProxy>();

        for (Object keyObject : input.keySet()) {
            output.put(String.valueOf(keyObject), context.proxify(input.get(keyObject)));
        }

        return output;
    }

    public static List<TransitProxy> convertArray(TransitContext context, Iterable<?> input) {
        List<TransitProxy> output = new LinkedList<TransitProxy>();

        for (Object o : input) {
            output.add(context.proxify(o));
        }

        return output;
    }

    public TransitProxy get(String key) {
        return getObjectValue().get(key);
    }

    public TransitProxy get(int index) {
        return getArrayValue().get(index);
    }

    public Object get() {
        switch (type) {
        case ARRAY:
            return arrayValue;
        case BOOLEAN:
            return booleanValue;
        case NUMBER:
            return numberValue;
        case OBJECT:
            return objectValue;
        case STRING:
            return stringValue;
        default:
            return null;
        }
    }

    private void assertType(Type expected) {
        if (type != expected && type != Type.NULL) {
            throw new AssertionError(String.format(
                    "Expected value to be %s but was %s", expected, type));
        }
    }

    public String getStringValue() {
        assertType(Type.STRING);
        return stringValue;
    }

    public int getIntegerValue() {
        assertType(Type.NUMBER);
        return numberValue.intValue();
    }

    public float getFloatValue() {
        assertType(Type.NUMBER);
        return numberValue.floatValue();
    }

    public double getDoubleValue() {
        assertType(Type.NUMBER);
        return numberValue.doubleValue();
    }

    public boolean getBooleanValue() {
        assertType(Type.BOOLEAN);
        return booleanValue.booleanValue();
    }

    public List<TransitProxy> getArrayValue() {
        assertType(Type.ARRAY);
        return arrayValue;
    }

    public Map<String, TransitProxy> getObjectValue() {
        assertType(Type.OBJECT);
        return this.objectValue;
    }

    @Override
    public String toString() {
        return String.format("[TransitProxy type:%s value:%s]", type, get());
    }

    public TransitProxy proxify(Object value) {

        if (value instanceof TransitProxy) {
            TransitProxy other = (TransitProxy) value;

            if (other.getRootContext() == this) {
                return (TransitProxy) value;
            } else {
                value = other.get();
            }
        }

        if (value instanceof String) {
            return createFromString(rootContext, (String) value);
        }

        TransitProxy result = new TransitProxy(rootContext);

        if (value instanceof Boolean) {
            result.type = Type.BOOLEAN;
            result.booleanValue = (Boolean) value;
        } else if (value instanceof Number) {
            result.type = Type.NUMBER;
            result.numberValue = (Number) value;
        } else if (value instanceof Object[]) {
            result.type = Type.ARRAY;
            result.arrayValue = convertArray(rootContext, Arrays.asList((Object[]) value));
        } else if (value instanceof List) {
            result.type = Type.ARRAY;
            result.arrayValue = convertArray(rootContext, (List<?>) value);
        } else if (value instanceof Map<?, ?>) {
            result.type = Type.OBJECT;
            result.objectValue = convertMap(rootContext, (Map<?, ?>) value);
        } else if (value == null) {
            result.type = Type.NULL;
            result.objectValue = null;
        } else {
            throw new IllegalArgumentException(String.format("TransitProxy doesn't support instances of `%s`", value.getClass().getName()));
        }

        return result;
    }

    public TransitProxy eval(String stringToEvaluate) {
        return eval(stringToEvaluate, new Object[0]);
    }

    public TransitProxy eval(String stringToEvaluate, Object... arguments) {
        return evalWithContext(stringToEvaluate, this, arguments);
    }

    public TransitProxy evalWithContext(String stringToEvaluate, Object context) {
        return evalWithContext(stringToEvaluate, context, new Object[0]);
    }

    public TransitProxy evalWithContext(String stringToEvaluate, Object context,
            Object... arguments) {
        return rootContext.eval(stringToEvaluate, context, arguments);
    }

    public String jsExpressionFromCode(String stringToEvaluate,
            Object... arguments) {
        StringBuffer output = new StringBuffer();
        Pattern pattern = Pattern.compile("(.*?)@");
        Matcher matcher = pattern.matcher(stringToEvaluate);

        int index = 0;
        while (matcher.find()) {
            output.append(matcher.group(1));
            String replacement = "";

            if (index >= arguments.length) {
                matcher.appendReplacement(output, "@");
                continue;
            }

            Object argument = arguments[index];

            if (argument instanceof JavaScriptRepresentable) {
                replacement = ((JavaScriptRepresentable) argument).getJavaScriptRepresentation();
            } else {
                replacement = proxify(argument).getJavaScriptRepresentation();
            }

            matcher.appendReplacement(output, replacement);
            index++;
        }

        matcher.appendTail(output);
        return output.toString();
    }

    @Override
    public String getJavaScriptRepresentation() {
        switch (type) {
        case NULL:
            return "null";
        case OBJECT:
            return "{}";
        case NUMBER:
            return String.valueOf(numberValue);
        case BOOLEAN:
            return String.valueOf(booleanValue);
        case STRING:
            return "\"" + stringValue + "\""; // TODO escaping
        case ARRAY:
            StringBuilder builder = new StringBuilder("[");
            boolean first = true;
            for (TransitProxy item : arrayValue) {
                if (first) {
                    first = false;
                } else {
                    builder.append(", ");
                }

                builder.append(item.getJavaScriptRepresentation());
            }
            builder.append("]");
            return builder.toString();
        default:
            return "{}";
        }
    }
}

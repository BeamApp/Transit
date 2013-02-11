package com.getbeamapp.transit;

import java.lang.reflect.Array;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.json.JSONObject;

public class TransitProxy implements JavaScriptRepresentable {
    public enum Type {
        UNKNOWN,
        BOOLEAN,
        NUMBER,
        STRING,
        ARRAY,
        OBJECT
    }

    protected Type type = Type.UNKNOWN;

    protected AbstractTransitContext rootContext;

    private Object value;

    public TransitProxy(AbstractTransitContext rootContext) {
        this.rootContext = rootContext;
    }

    public static TransitProxy withValue(AbstractTransitContext rootContext,
            Object value) {
        TransitProxy result = new TransitProxy(rootContext);

        if (value instanceof Boolean) {
            result.type = Type.BOOLEAN;
        } else if (value instanceof Number) {
            result.type = Type.NUMBER;
        } else if (value instanceof String) {
            result.type = Type.STRING;
        } else if (value instanceof Array || value instanceof List) {
            result.type = Type.ARRAY;
        } else if (value instanceof Map) {
            result.type = Type.OBJECT;
        } else {
            throw new IllegalArgumentException(String.format("TransitProxy doesn't support instances of `%s`", value.getClass().getName()));
        }

        result.value = value;
        return result;
    }

    public TransitProxy get(String key) {
        return null;
    }

    public TransitProxy get(int index) {
        return null;
    }

    public Object get() {
        return value;
    }

    private void assertType(Type expected) {
        if (type != expected) {
            throw new AssertionError(String.format(
                    "Expected value to be %s but was %s", expected, type));
        }
    }

    public String getStringValue() {
        assertType(Type.STRING);
        return (String) value;
    }

    public int getIntegerValue() {
        assertType(Type.NUMBER);
        return (Integer) value;
    }

    public float getFloatValue() {
        assertType(Type.NUMBER);
        return (Float) value;
    }

    public double getDoubleValue() {
        assertType(Type.NUMBER);
        return (Double) value;
    }

    public boolean getBooleanValue() {
        assertType(Type.BOOLEAN);
        return (Boolean) value;
    }

    public Array getArrayValue() {
        assertType(Type.ARRAY);
        return (Array) value;
    }

    public Map<String, Object> getObjectValue() {
        assertType(Type.OBJECT);
        return new HashMap<String, Object>();
    }

    @Override
    public String toString() {
        return String.format("[TransitProxy type:%s value:%s]", type, value);
    }

    public TransitProxy eval(String stringToEvaluate) {
        return eval(stringToEvaluate, this, new Object[0]);
    }

    public TransitProxy eval(String stringToEvaluate, Object... arguments) {
        return eval(stringToEvaluate, this, new Object[0]);
    }

    public TransitProxy eval(String stringToEvaluate, TransitProxy context,
            Object... arguments) {
        return rootContext.eval(stringToEvaluate, context, arguments);
    }

    public static String jsExpressionFromCode(String stringToEvaluate,
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
                replacement = ((JavaScriptRepresentable) argument)
                        .getJavaScriptRepresentation();
            } else if (argument instanceof Boolean) {
                replacement = String.valueOf(argument);
            } else if (argument instanceof Number) {
                replacement = String.valueOf(argument);
            } else if (argument instanceof String) {
                replacement = JSONObject.quote((String) argument);
            } else if (argument instanceof Array) {
                replacement = "[]"; // TODO
            } else if (argument instanceof Map) {
                replacement = "{}"; // TODO
            } else if (argument == null) {
                replacement = "null";
            } else {
                throw new IllegalArgumentException("Argument at index " + index
                        + " can't be serialized.");
            }

            matcher.appendReplacement(output, replacement);
            index++;
        }

        matcher.appendTail(output);
        return output.toString();
    }

    public static TransitProxy proxify(AbstractTransitContext context, Object o) {
        if (o instanceof TransitProxy) {
            return (TransitProxy) o;
        } else {
            return withValue(context, o);
        }
    }

    @Override
    public String getJavaScriptRepresentation() {
        return "{}";
    }
}

package com.getbeamapp.transit;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.json.JSONObject;

public class TransitScriptBuilder {
    private static class ArgumentList implements Iterable<Object> {

        private final Iterable<Object> iterable;

        public ArgumentList(Iterable<Object> i) {
            this.iterable = i;
        }

        @Override
        public Iterator<Object> iterator() {
            return iterable.iterator();
        }

    }

    private static class RawExpression {
        public final String string;

        public RawExpression(String s) {
            this.string = s;
        }
    }

    public static Iterable<Object> arguments(Object... items) {
        return new ArgumentList(Arrays.asList(items));
    }

    public static Object raw(String s) {
        return new RawExpression(s);
    }

    private StringBuilder buffer;
    private final StringBuilder vars = new StringBuilder();
    private final Set<String> definedVars = new HashSet<String>();
    private String result = null;
    private final String thisArgExpression;

    public TransitScriptBuilder(String transitVariable, Object thisArg) {
        buffer = new StringBuilder();

        if (thisArg == null || thisArg instanceof TransitContext) {
            this.thisArgExpression = null;
        } else {
            parse(thisArg);
            this.thisArgExpression = buffer.toString();
        }

        this.buffer = new StringBuilder();
    }

    public void process(String stringToEvaluate, Object... values) {
        int start = 0;
        int index = 0;
        int length = stringToEvaluate.length();
        int valueIndex = 0;

        while ((index = stringToEvaluate.indexOf('@', start)) >= 0) {
            if (index - start > 0) {
                buffer.append(stringToEvaluate.substring(start, index));
            }

            if (valueIndex < values.length) {
                parse(values[valueIndex++]);
            }

            start = index + 1;
        }

        if (start < length) {
            buffer.append(stringToEvaluate.substring(start, length));
        }
    }

    public String toScript() {
        if (result != null) {
            return result;
        }

        StringBuilder output = new StringBuilder();
        boolean hasVars = !definedVars.isEmpty();

        if (hasVars) {
            output.append("(function() {\n  ");
            output.append(vars);
            output.append(";\n  return ");
        }

        if (thisArgExpression != null) {
            output.append("(function() {\n    return ");
            output.append(buffer);
            output.append(";\n  }).call(");
            output.append(thisArgExpression);
            output.append(")");
        } else {
            output.append(buffer);
        }

        if (hasVars) {
            output.append(";\n");
            output.append("})()");
        }

        result = output.toString();
        return result;
    }

    private void addVariable(String variableName, Object... fragments) {
        if (!definedVars.contains(variableName)) {
            if (definedVars.size() == 0) {
                vars.append("var ");
            } else {
                vars.append(", ");
            }

            definedVars.add(variableName);

            vars.append(variableName);
            vars.append(" = ");

            StringBuilder _buffer = buffer;
            buffer = vars;

            try {
                for (Object fragment : fragments) {
                    parse(fragment);
                }
            } finally {
                buffer = _buffer;
            }
        }

        buffer.append(variableName);
    }

    private void parse(Object o) {
        if (o instanceof JSRepresentable) {
            buffer.append(((JSRepresentable) o).getJSRepresentation());
        } else if (o instanceof TransitProxy) {
            TransitProxy p = (TransitProxy) o;

            if (p instanceof TransitNativeFunction) {
                TransitNativeFunction f = (TransitNativeFunction) p;
                Object options = f.getJSOptions();

                if (options != null) {
                    addVariable(getVariable(f), raw("transit.nativeFunction("), arguments(f.getProxyId(), options), raw(")"));
                } else {
                    addVariable(getVariable(f), raw("transit.nativeFunction("), f.getProxyId(), raw(")"));
                }

            } else if (p.getProxyId() != null) {
                addVariable(getVariable(p), raw("transit.r("), p.getProxyId(), raw(")"));
            } else {
                parseNative(o);
            }
        } else if (o instanceof TransitContext) {
            buffer.append("window");
        } else {
            parseNative(o);
        }
    }

    private void parseNative(Object o) {
        if (o == null) {
            buffer.append("null");
        } else if (o instanceof RawExpression) {
            buffer.append(((RawExpression) o).string);
        } else if (o.getClass().isArray()) {
            parseArray(o);
        } else if (o instanceof Iterable<?>) {
            parse((Iterable<?>) o);
        } else if (o instanceof TransitJSObject || o instanceof Map<?, ?>) {
            parse((Map<?, ?>) o);
        } else if (o instanceof Number || o instanceof Boolean) {
            buffer.append(String.valueOf(o));
        } else if (o instanceof String) {
            buffer.append(JSONObject.quote((String) o));
        } else {
            throw new IllegalArgumentException(String.format("Can't convert %s to JavaScript. Try to implement %s.",
                    o.getClass().getCanonicalName(),
                    JSRepresentable.class.getCanonicalName()));
        }
    }

    private void parseArray(Object array) {
        int l = Array.getLength(array);
        List<Object> list = new ArrayList<Object>(l);

        for (int i = 0; i < l; i++) {
            list.add(Array.get(array, i));
        }

        parse(list);
    }

    private void parse(Map<?, ?> o) {
        buffer.append("{");

        boolean first = true;
        for (Object key : o.keySet()) {
            if (first) {
                first = false;
            } else {
                buffer.append(", ");
            }

            buffer.append(JSONObject.quote(key.toString()));
            buffer.append(": ");

            parse(o.get(key));
        }

        buffer.append("}");
    }

    private void parse(Iterable<?> iterable) {
        if (!(iterable instanceof ArgumentList)) {
            buffer.append("[");
        }

        boolean first = true;
        for (Object o : iterable) {
            if (first) {
                first = false;
            } else {
                buffer.append(", ");
            }

            parse(o);
        }

        if (!(iterable instanceof ArgumentList)) {
            buffer.append("]");
        }
    }

    private String getVariable(TransitProxy p) {
        if (p instanceof TransitNativeFunction) {
            TransitNativeFunction f = (TransitNativeFunction) p;
            return "__TRANSIT_NATIVE_FUNCTION_" + f.getNativeId();
        } else if (p instanceof TransitJSFunction) {
            return "__TRANSIT_JS_FUNCTION_" + p.getProxyId();
        } else {
            return "__TRANSIT_OBJECT_PROXY_" + p.getProxyId();
        }
    }
}

package com.getbeamapp.transit;

import java.lang.reflect.Array;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.json.JSONObject;

public class TransitScriptBuilder {
    private StringBuffer buffer;
    private final StringBuffer vars = new StringBuffer();
    private final Set<String> definedVars = new HashSet<String>();
    private final String QUOTE = "\"";
    private String result = null;
    private final String thisArgExpression;

    public TransitScriptBuilder(String transitVariable, Object thisArg) {
        buffer = new StringBuffer();

        if (thisArg == null || thisArg instanceof TransitContext) {
            this.thisArgExpression = null;
        } else {
            parse(thisArg);
            this.thisArgExpression = buffer.toString();
        }

        this.buffer = new StringBuffer();
    }

    public void process(String stringToEvaluate, Object... values) {
        Pattern pattern = Pattern.compile("(.*?)@");
        Matcher matcher = pattern.matcher(stringToEvaluate);

        int index = 0;

        while (matcher.find()) {
            buffer.append(matcher.group(1));

            if (index >= values.length) {
                matcher.appendReplacement(buffer, "@");
                continue;
            } else {
                parse(values[index]);
                matcher.appendReplacement(buffer, "");
            }

            index++;
        }

        matcher.appendTail(buffer);
    }

    public String toScript() {
        if (result != null) {
            return result;
        }

        StringBuffer output = new StringBuffer();
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

    private void addVariable(String variableName, String... strings) {
        if (!definedVars.contains(variableName)) {
            if (definedVars.size() == 0) {
                vars.append("var ");
            } else {
                vars.append(", ");
            }

            definedVars.add(variableName);

            vars.append(variableName);
            vars.append(" = ");

            for (String string : strings) {
                vars.append(string);
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
                addVariable(getVariable(f), "transit.nativeFunction(", QUOTE, f.getNativeId(), QUOTE, ")");
            } else if (p instanceof TransitContext) {
                addVariable(getVariable(p), "window");
            } else if (p.getProxyId() != null) {
                addVariable(getVariable(p), "transit.r(", QUOTE, p.getProxyId(), QUOTE, ")");
            } else {
                parseNative(o);
            }
        } else {
            parseNative(o);
        }
    }

    private void parseNative(Object o) {
        if (o == null) {
            buffer.append("null");
        } else if (o.getClass().isArray()) {
            parse((Array) o);
        } else if (o instanceof Collection<?>) {
            parse((Collection<?>) o);
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

    private void parse(Array array) {
        parse(Arrays.asList(array));
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

            parse(o);
        }

        buffer.append("}");
    }

    private void parse(Iterable<?> iterable) {
        buffer.append("[");

        for (Object o : iterable) {
            parse(o);
        }

        buffer.append("]");
    }

    private String getVariable(TransitProxy p) {
        if (p instanceof TransitNativeFunction) {
            TransitNativeFunction f = (TransitNativeFunction) p;
            return "__TRANSIT_NATIVE_FUNCTION_" + f.getNativeId();
        } else if (p instanceof TransitJSFunction) {
            return "__TRANSIT_JS_FUNCTION_" + p.getProxyId();
        } else if (p instanceof TransitContext) {
            return "__TRANSIT_OBJECT_GLOBAL";
        }

        return "__TRANSIT_OBJECT_PROXY" + p.getProxyId();
    }
}

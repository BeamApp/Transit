package com.getbeamapp.transit;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.json.JSONException;
import org.json.JSONObject;

public class TransitProxy {
	public enum Type {
		UNKNOWN, BOOLEAN, NUMBER, STRING, ARRAY, OBJECT
	}

	protected Type type = Type.UNKNOWN;

	protected AbstractTransitContext rootContext;

	public TransitProxy(AbstractTransitContext rootContext) {
		this.rootContext = rootContext;
	}

	public Object get(String key) {
		return null;
	}

	public Object get(int index) {
		return null;
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
			
			if(index >= arguments.length) {
				matcher.appendReplacement(output, "@");
				continue;
			}
			
			Object argument = arguments[index];
			
			if (argument instanceof JavaScriptRepresentable) {
				replacement = ((JavaScriptRepresentable)argument).getJavaScriptRepresentation();
			} else if (argument instanceof String) {
				replacement = JSONObject.quote((String)argument);
			} else if (argument instanceof Float ) {
				replacement = String.valueOf(argument);
			} else if (argument instanceof Double ) {
				replacement = String.valueOf(argument);
			} else if (argument instanceof Integer ) {
				replacement = String.valueOf(argument);
			} else if (argument instanceof Boolean) {
				replacement = String.valueOf(argument);
			} else if (argument == null) {
				replacement = "null";
			} else {
				throw new IllegalArgumentException("Argument at index " + index + " can't be serialized.");
			}
			
			matcher.appendReplacement(output, replacement);
			index++;
		}
		
		matcher.appendTail(output);
		return output.toString();
	}
}

package com.getbeamapp.transit;

import java.util.HashMap;
import java.util.Map;
import java.util.Stack;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;

import org.json.JSONException;
import org.json.JSONObject;

import android.os.ConditionVariable;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.webkit.JsPromptResult;
import android.webkit.WebChromeClient;
import android.webkit.WebView;

public class TransitWebChromeClient extends WebChromeClient {

	public static final String MAGIC_INVOKE_IDENTIFIER = "__TRANSIT_MAGIC_INVOKE";
	public static final String MAGIC_POLL_IDENTIFIER = "__TRANSIT_MAGIC_POLL";
	public static final String MAGIC_RETURN_IDENTIFIER = "__TRANSIT_MAGIC_RETURN";

	private final Stack<TransitAction> actions = new Stack<TransitAction>();

	private final Semaphore lock = new Semaphore(0);

	public interface TransitNativeFunction {
		public Object callWithContextAndArguments(Object thisArg, Object[] args);
	}

	private class TransitAction {

		public String toJavaScript() {
			return toString();
		}
	}

	private class TransitExceptionAction extends TransitAction {
		private Exception exception;

		public TransitExceptionAction(Exception e) {
			this.exception = e;
		}
	}

	private class TransitReturnResultAction extends TransitAction {
		private Object object;

		public TransitReturnResultAction(Object o) {
			this.object = o;
		}
	}

	private class TransitEvalAction extends TransitAction {
		private String stringToEvaluate;

		public final ConditionVariable lock = new ConditionVariable();

		public TransitProxy result;

		public RuntimeException exception;

		public TransitEvalAction(String stringToEvaluate) {
			this.stringToEvaluate = stringToEvaluate;
		}

		@Override
		public String toJavaScript() {
			return stringToEvaluate;
		}
	}

	private final Map<String, TransitNativeFunction> callbacks = new HashMap<String, TransitWebChromeClient.TransitNativeFunction>();

	final WebView webView;
	private TransitContext context;

	public TransitWebChromeClient(WebView webView) {
		super();
		this.webView = webView;
	}
	
	public TransitProxy unmarshal(Object o) {
		return new TransitProxy(context);
	}
	
	public void setTransitContext(TransitContext context) {
		this.context = context;
	}

	public Object unmarshalJson(String dataAsString) {
		try {
			JSONObject object = new JSONObject("{\"data\": " + dataAsString + "}");
			return object.get("data");
		} catch (JSONException e) {
			throw new RuntimeException(e);
		}
	}

	@Override
	public boolean onJsPrompt(WebView view, String url, String message,
			String defaultValue, JsPromptResult result) {

		Log.d("TransitWCC", message);

		if (message.equals(MAGIC_INVOKE_IDENTIFIER)) {
			invoke(unmarshal(defaultValue));
			process(result);
		} else if (message.equals(MAGIC_RETURN_IDENTIFIER)) {
			TransitEvalAction action = waitingEvaluations.pop();
			action.result = unmarshal(defaultValue);
			action.lock.open();
			process(result);
		} else if (message.equals(MAGIC_POLL_IDENTIFIER)) {
			process(result);
		} else {
			return super.onJsPrompt(view, url, message, defaultValue, result);
		}

		return true;
	}

	public void runOnUiThread(Runnable runnable) {
		if (isUiThread()) {
			runnable.run();
		} else {
			new Handler(Looper.getMainLooper()).post(runnable);
		}
	}

	public TransitProxy evaluate(String stringToEvaluate) {
		TransitEvalAction action = new TransitEvalAction(stringToEvaluate);
		actions.push(action);
		lock.release();

		runOnUiThread(new Runnable() {
			@Override
			public void run() {
				webView.loadUrl("javascript:prompt('" + MAGIC_RETURN_IDENTIFIER
						+ "', JSON.stringify(eval(prompt('"
						+ MAGIC_POLL_IDENTIFIER + "'))))");
			}
		});

		action.lock.block();

		if (action.exception != null) {
			throw action.exception;
		} else {
			return action.result;
		}
	}

	private boolean isUiThread() {
		return Looper.getMainLooper().getThread() == Thread.currentThread();
	}

	private void invoke(final Object descriptionString) {
		final TransitNativeFunction callback = callbacks.get(descriptionString);

		new Thread(new Runnable() {
			@Override
			public void run() {
				try {
					Object result = callback.callWithContextAndArguments(null,
							null);
					actions.push(new TransitReturnResultAction(result));
				} catch (Exception e) {
					actions.push(new TransitExceptionAction(e));
				} finally {
					lock.release();
				}
			}
		}).start();
	}

	private final Stack<TransitEvalAction> waitingEvaluations = new Stack<TransitEvalAction>();

	private void process(final JsPromptResult result) {
		Runnable toExecute = new Runnable() {
			@Override
			public void run() {
				TransitAction action = null;

				try {
					lock.acquire();
				} catch (Exception e) {
					result.confirm(new TransitExceptionAction(e).toString());
					return;
				}

				action = actions.pop();

				if (action instanceof TransitEvalAction) {
					waitingEvaluations.push((TransitEvalAction) action);
				}

				result.confirm(action.toJavaScript());
			}
		};

		if (isUiThread()) {
			Executors.newSingleThreadExecutor().execute(toExecute);
		} else {
			toExecute.run();
		}

	}
}

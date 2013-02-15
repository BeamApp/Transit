package com.getbeamapp.transit.prompt;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Stack;
import java.util.concurrent.Executors;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.res.Resources;
import android.os.ConditionVariable;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.webkit.JsPromptResult;
import android.webkit.WebChromeClient;
import android.webkit.WebView;

import com.getbeamapp.transit.AndroidTransitContext;
import com.getbeamapp.transit.JsonConverter;
import com.getbeamapp.transit.R;
import com.getbeamapp.transit.TransitAdapter;
import com.getbeamapp.transit.TransitException;
import com.getbeamapp.transit.TransitNativeFunction;
import com.getbeamapp.transit.TransitJSObject;

public class TransitChromeClient extends WebChromeClient implements TransitAdapter {

    enum TransitRequest {
        INVOKE("__TRANSIT_MAGIC_INVOKE"),
        POLL("__TRANSIT_MAGIC_POLL"),
        RETURN("__TRANSIT_MAGIC_RETURN"),
        EXCEPTION("__TRANSIT_MAGIC_EXCEPTION");

        private String string;

        TransitRequest(String string) {
            assert (string != null);
            this.string = string;
        }

        public String getString() {
            return string;
        }

        public boolean equals(String string) {
            return this.string.equals(string);
        }
    }

    enum TransitResponse {
        RETURN("RETURN"),
        EXCEPTION("EXCEPTION"),
        EVAL("EVAL");

        private String string;

        TransitResponse(String string) {
            assert (string != null);
            this.string = string;
        }

        public String getString() {
            return string;
        }

        public boolean equals(String string) {
            return this.string.equals(string);
        }
    }

    public static final String TAG = "TransitAdapter";

    private final Stack<TransitAction> actions = new Stack<TransitAction>();

    private final ConditionVariable lock = new ConditionVariable(true);

    final WebView webView;
    private AndroidTransitContext context;

    private boolean active = false;

    public TransitChromeClient(WebView forWebView) {
        super();
        this.webView = forWebView;
        this.webView.setWebChromeClient(this);
    }

    public final void initialize() {
        Log.d(TAG, "Injecting script...");
        webView.loadUrl("javascript:" + getScript());
    }

    public static AndroidTransitContext createContext(WebView webView) {
        return createContext(webView, new TransitChromeClient(webView));
    }

    public static AndroidTransitContext createContext(WebView webView, TransitChromeClient adapter) {
        assert adapter.webView == webView;
        adapter.context = new AndroidTransitContext(adapter);
        return adapter.context;
    }

    private final Object unmarshal(String dataAsJsonString) {
        Object o = unmarshalJson(dataAsJsonString);

        if (o == null) {
            return null;
        } else {
            return JsonConverter.toNative(o);
        }
    }

    private final Object unmarshalJson(String dataAsJsonString) {
        if (dataAsJsonString == null) {
            return null;
        } else {
            try {
                JSONObject object = new JSONObject(dataAsJsonString);
                return object.get("data");
            } catch (JSONException e) {
                throw new TransitException("Failed to parse JSON payload", e);
            }
        }
    }

    @Override
    public boolean onJsPrompt(WebView view, String url, String message,
            String defaultValue, JsPromptResult result) {

        Log.d(TAG, String.format("%s --- %s", message, defaultValue));
        active = true;

        if (TransitRequest.INVOKE.equals(message)) {
            doInvokeNative(context.proxify(unmarshal(defaultValue)));
            process(result);
        } else if (TransitRequest.RETURN.equals(message)) {
            if (waitingEvaluations.empty()) {
                // TODO: raise NotExpected exception
            } else {
                TransitEvalAction action = waitingEvaluations.pop();
                Object returnValue = unmarshal(defaultValue);
                action.resolveWith(returnValue);
                Log.i(TAG, String.format("Resolved `%s` with `%s`", action.getStringToEvaluate(), returnValue));
                process(result);
            }
        } else if (TransitRequest.EXCEPTION.equals(message)) {
            if (waitingEvaluations.empty()) {
                Log.d(TAG, String.format("Got exception from JavaScript: %s", defaultValue));
            } else {
                TransitEvalAction action = waitingEvaluations.pop();
                String error = String.valueOf(unmarshalJson(defaultValue));
                action.rejectWith(error);
                Log.i(TAG, String.format("Rejected `%s` with `%s`", action.getStringToEvaluate(), error));
            }

            process(result);
        } else if (TransitRequest.POLL.equals(message)) {
            process(result);
        } else {
            return super.onJsPrompt(view, url, message, defaultValue, result);
        }

        return true;
    }

    private boolean isUiThread() {
        return Looper.getMainLooper().getThread() == Thread.currentThread();
    }

    private void runOnUiThread(Runnable runnable) {
        if (isUiThread()) {
            runnable.run();
        } else {
            new Handler(Looper.getMainLooper()).post(runnable);
        }
    }

    public void runOnNonUiThread(Runnable runnable) {
        if (isUiThread()) {
            Executors.newSingleThreadExecutor().execute(runnable);
        } else {
            runnable.run();
        }
    }

    private void pushAction(TransitAction action) {
        this.actions.push(action);
        this.lock.open();
    }

    @Override
    public void releaseProxy(String proxyId) {
        webView.loadUrl(String.format("javascript:transit.releaseProxy(%s)", JSONObject.quote(proxyId)));
    }

    public final Object evaluate(String stringToEvaluate) {
        // TODO: Make sure no "outside" evaluate-calls cause conflicts with
        // active Transit threads

        Log.d(TAG, String.format("Evaluate %s (active: %s)", stringToEvaluate, active));
        TransitEvalAction action = new TransitEvalAction(stringToEvaluate);
        pushAction(action);

        if (!active) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Log.d(TAG, "transit.poll()");
                    webView.loadUrl("javascript:transit.poll()");
                }
            });
        }

        Log.i(TAG, String.format("Waiting for `%s`", stringToEvaluate));
        return action.block();
    }

    public void readResource(int id, ByteArrayOutputStream output) {
        try {
            Resources res = webView.getResources();
            InputStream inputStream = res.openRawResource(id);

            byte[] readBuffer = new byte[4 * 1024];

            int read;

            do {
                read = inputStream.read(readBuffer, 0, readBuffer.length);
                if (read == -1) {
                    break;
                }

                output.write(readBuffer, 0, read);
            } while (true);
        } catch (IOException e) {
            throw new TransitException(e);
        }
    }

    public String getScript() {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        readResource(R.raw.transit, output);
        readResource(R.raw.runtime, output);
        return output.toString();
    }

    private void doInvokeNative(final Object _invocationDescription) {
        lock.close();

        TransitJSObject invocationDescription = (TransitJSObject) _invocationDescription;

        final String nativeId = (String) invocationDescription.get("nativeId");
        final Object thisArg = (Object) invocationDescription.get("thisArg");

        @SuppressWarnings("unchecked")
        final Object[] arguments = ((List<Object>) invocationDescription.get("args")).toArray(new Object[0]);

        Log.d(TAG, String.format("Invoking native function `%s`", nativeId));

        final TransitNativeFunction callback = context.getCallback(nativeId);

        if (callback == null) {
            pushAction(new TransitExceptionAction(String.format("Can't find native function for native ID `%s`", nativeId)));
        } else {
            Executors.newSingleThreadExecutor().execute(new Runnable() {
                @Override
                public void run() {
                    TransitAction action = null;

                    try {
                        Object resultObject = callback.call(thisArg, arguments);
                        String result = context.convertObjectToExpression(resultObject);
                        action = new TransitReturnResultAction(result);
                        Log.d(TAG, String.format("Invoked native function `%s` with result `%s`", nativeId, resultObject));
                    } catch (Exception e) {
                        Log.e(TAG, String.format("Exception invoking native function `%s`", nativeId), e);
                        action = new TransitExceptionAction(e);
                    } finally {
                        if (action != null) {
                            pushAction(action);
                        }
                    }
                }
            });
        }
    }

    private final Stack<TransitEvalAction> waitingEvaluations = new Stack<TransitEvalAction>();

    private void process(final JsPromptResult result) {
        runOnNonUiThread(new Runnable() {
            @Override
            public void run() {
                lock.block();

                if (actions.empty()) {
                    active = false;
                    result.confirm();
                    return;
                }

                TransitAction action = actions.pop();

                if (action instanceof TransitEvalAction) {
                    waitingEvaluations.push((TransitEvalAction) action);
                }

                String response = action.getJSRepresentation();
                Log.d(TAG, String.format("Returning %s", response));
                result.confirm(response);
            }
        });
    }
}

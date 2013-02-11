package com.getbeamapp.transit.prompt;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Stack;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.res.Resources;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.webkit.JsPromptResult;
import android.webkit.WebChromeClient;
import android.webkit.WebView;

import com.getbeamapp.transit.R;
import com.getbeamapp.transit.TransitAdapter;
import com.getbeamapp.transit.TransitContext;
import com.getbeamapp.transit.TransitException;
import com.getbeamapp.transit.TransitProxy;

public class TransitChromeClient extends WebChromeClient implements TransitAdapter {

    public enum TransitRequest {
        INVOKE("__TRANSIT_MAGIC_INVOKE"),
        POLL("__TRANSIT_MAGIC_POLL"),
        RETURN("__TRANSIT_MAGIC_RETURN"),
        EXCEPTION("__TRANSIT_MAGIC_EXCEPTION");

        private String string;

        TransitRequest(String string) {
            assert (string != null);
            this.string = string;
        }

        public boolean equals(String string) {
            return this.string.equals(string);
        }
    }

    public static final String TAG = "TransitAdapter";

    private final Stack<TransitAction> actions = new Stack<TransitAction>();

    private final Semaphore lock = new Semaphore(0);

    public interface TransitNativeFunction {
        public Object callWithContextAndArguments(Object thisArg, Object[] args);
    }

    private final Map<String, TransitNativeFunction> callbacks = new HashMap<String, TransitChromeClient.TransitNativeFunction>();

    final WebView webView;
    private TransitContext context;

    public TransitChromeClient(WebView forWebView) {
        super();
        this.webView = forWebView;
        this.webView.setWebChromeClient(this);
    }

    public final void initialize() {
        Log.d(TAG, "Injecting script...");
        webView.loadUrl("javascript:" + getScript());
    }

    public static TransitContext createContext(WebView webView) {
        return createContext(webView, new TransitChromeClient(webView));
    }

    public static TransitContext createContext(WebView webView, TransitChromeClient adapter) {
        assert adapter.webView == webView;
        adapter.context = new TransitContext(adapter);
        return adapter.context;
    }

    private final TransitProxy unmarshal(String dataAsJsonString) {
        Object o = unmarshalJson(dataAsJsonString);

        if (o == null) {
            return null;
        } else {
            return TransitProxy.withValue(context, o);
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

        if (TransitRequest.INVOKE.equals(message)) {
            invoke(unmarshal(defaultValue));
            process(result);
        } else if (TransitRequest.RETURN.equals(message)) {
            TransitEvalAction action = waitingEvaluations.pop();
            action.result = unmarshal(defaultValue);
            action.lock.open();
            Log.i(TAG, String.format("Resolved `%s`", action.stringToEvaluate));
            process(result);
        } else if (TransitRequest.EXCEPTION.equals(message)) {
            if (waitingEvaluations.empty()) {
                Log.d(TAG, String.format("Got exception from JavaScript: %s", defaultValue));
            } else {
                TransitEvalAction action = waitingEvaluations.pop();
                action.exception = new TransitException(String.valueOf(unmarshalJson(defaultValue)));
                action.lock.open();
            }

            process(result);
        } else if (TransitRequest.POLL.equals(message)) {
            lock.release(); // peek for free
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

    public final TransitProxy evaluate(String stringToEvaluate) {
        TransitEvalAction action = new TransitEvalAction(stringToEvaluate);

        actions.push(action);
        lock.release();
        Log.i(TAG, "Pushed action and released Lock");

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.d(TAG, "transit.poll()");
                webView.loadUrl("javascript:transit.poll()");
            }
        });

        Log.i(TAG, String.format("Waiting for `%s`", stringToEvaluate));
        action.lock.block();

        if (action.exception != null) {
            Log.i(TAG, String.format("Got exception for `%s`: %s",
                    stringToEvaluate, action.exception));
            throw action.exception;
        } else {
            Log.i(TAG, String.format("Got result for `%s`: %s",
                    stringToEvaluate, action.result));
            return action.result;
        }
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
                    Log.i(TAG, "Pushed action and released Lock");
                    lock.release();
                }
            }
        }).start();
    }

    private final Stack<TransitEvalAction> waitingEvaluations = new Stack<TransitEvalAction>();

    private void process(final JsPromptResult result) {
        runOnNonUiThread(new Runnable() {
            @Override
            public void run() {
                TransitAction action = null;

                Log.i(TAG, "Acquire lock");

                try {
                    lock.acquire();
                } catch (InterruptedException e) {
                    result.confirm(new TransitExceptionAction(e).toString());
                    return;
                }

                if (actions.isEmpty()) {
                    result.confirm();
                    return;
                }

                action = actions.pop();

                if (action instanceof TransitEvalAction) {
                    waitingEvaluations.push((TransitEvalAction) action);
                }

                String response = action.toJavaScript();
                Log.d(TAG, String.format("Returning %s", response));
                result.confirm(response);
            }
        });
    }
}

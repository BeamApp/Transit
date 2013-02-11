package com.getbeamapp.transit.prompt;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
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

import com.getbeamapp.transit.JsonConverter;
import com.getbeamapp.transit.R;
import com.getbeamapp.transit.TransitAdapter;
import com.getbeamapp.transit.TransitContext;
import com.getbeamapp.transit.TransitException;
import com.getbeamapp.transit.TransitNativeFunction;
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
            return TransitProxy.withValue(context, JsonConverter.toNative(o));
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

    public final TransitProxy evaluate(String stringToEvaluate) {
        TransitReturnResultAction returnAction = new TransitReturnResultAction(null);
        actions.push(returnAction);
        lock.release();
        
        TransitEvalAction action = new TransitEvalAction(stringToEvaluate);
        actions.push(action);
        lock.release();

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.d(TAG, "transit.poll()");
                webView.loadUrl("javascript:transit.poll()");
            }
        });

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

    private void invoke(final TransitProxy invokeDescriptor) {
        final String nativeId = (String)invokeDescriptor.getObjectValue().get("nativeId");
        final TransitNativeFunction callback = context.getCallback(nativeId);

        if (callback == null) {
            actions.push(new TransitExceptionAction(String.format("Can't find native function for native ID `%s`", nativeId)));
            lock.release();
        } else {
            Executors.newSingleThreadExecutor().execute(new Runnable() {
                @Override
                public void run() {
                    TransitAction action = null;

                    try {
                        Object resultObject = callback.call();
                        TransitProxy resultProxy = TransitProxy.proxify(context, resultObject);
                        action = new TransitReturnResultAction(resultProxy);
                    } catch (Exception e) {
                        Log.e(TAG, String.format("Exception invoking native function `%s`", nativeId), e);
                        action = new TransitExceptionAction(e);
                    } finally {
                        if (action != null) {
                            actions.push(action);
                            lock.release();
                            Log.i(TAG, "Pushed action and released Lock");
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
                TransitAction action = null;

                Log.i(TAG, "Acquire lock");

                try {
                    lock.acquire();
                } catch (InterruptedException e) {
                    result.confirm(new TransitExceptionAction(e).toString());
                    return;
                }

                if (actions.isEmpty()) {
                    throw new TransitException("Action list is empty.");
                }

                action = actions.pop();

                if (action instanceof TransitEvalAction) {
                    waitingEvaluations.push((TransitEvalAction) action);
                }

                String response = action.getJavaScriptRepresentation();
                Log.d(TAG, String.format("Returning %s", response));
                result.confirm(response);
            }
        });
    }
}

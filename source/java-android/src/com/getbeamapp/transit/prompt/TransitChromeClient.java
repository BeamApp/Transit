package com.getbeamapp.transit.prompt;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Stack;
import java.util.concurrent.BlockingDeque;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingDeque;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.res.Resources;
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
import com.getbeamapp.transit.TransitContext.PreparedInvocation;
import com.getbeamapp.transit.TransitException;
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

    private final BlockingDeque<TransitAction> actions = new LinkedBlockingDeque<TransitAction>();

    final WebView webView;
    private AndroidTransitContext context;

    private boolean active = false;

    private boolean polling = false;

    public TransitChromeClient(WebView forWebView) {
        super();
        this.webView = forWebView;
        this.webView.setWebChromeClient(this);
    }

    public final void initialize() {
        Log.d(TAG, "Injecting script...");
        this.active = false;
        this.polling = false;
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

        if (TransitRequest.INVOKE.equals(message)) {
            if (!isActive()) {
                begin();
            }
            doInvokeNative(context.proxify(unmarshal(defaultValue)));
            process(result);
        } else if (TransitRequest.RETURN.equals(message)) {
            assert isActive();
            assert !waitingEvaluations.empty();

            TransitEvalAction action = waitingEvaluations.pop();
            Object returnValue = context.proxify(unmarshal(defaultValue));
            action.resolveWith(returnValue);
            Log.d(TAG, String.format("%s -> %s", action.getStringToEvaluate(), returnValue));
            process(result);
        } else if (TransitRequest.EXCEPTION.equals(message)) {
            assert isActive();
            assert !waitingEvaluations.empty();

            TransitEvalAction action = waitingEvaluations.pop();
            String error = String.valueOf(unmarshalJson(defaultValue));
            action.rejectWith(error);
            Log.i(TAG, String.format("Rejected `%s` with `%s`", action.getStringToEvaluate(), error));
            process(result);
        } else if (TransitRequest.POLL.equals(message)) {
            assert !isActive();
            begin(true);
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
        assert action != null;
        this.actions.offerFirst(action);
    }

    @Override
    public void releaseProxy(String proxyId) {
        if (this.webView != null) {
            Log.d(TAG, String.format("Releasing proxy with id `%s`", proxyId));
            webView.loadUrl("javascript:transit.releaseElementWithId(\"" + proxyId + "\")");
        }
    }

    public final Object evaluate(String stringToEvaluate) {
        // TODO: Make sure no "outside" evaluate-calls cause conflicts with
        // active Transit threads

        boolean mustInitPoll = !isActive();

        TransitEvalAction action = new TransitEvalAction(stringToEvaluate);
        pushAction(action);

        if (mustInitPoll) {
            pollBegin();
        }

        Log.i(TAG, String.format("%s -> ...", stringToEvaluate));

        try {
            Object result = action.block();
            Log.i(TAG, String.format("%s -> %s", stringToEvaluate, result));
            return result;
        } finally {
            if (mustInitPoll) {
                pollComplete();
            }
        }
    }

    private void pollBegin() {
        assert !isActive();

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.i(TAG, "pollBegin()");
                webView.loadUrl("javascript:transit.poll()");
            }
        });
    }

    private void pollComplete() {
        assert isActive();
        assert isPolling();

        Log.i(TAG, "pollComplete()");
        TransitPollCompleteAction action = new TransitPollCompleteAction();
        pushAction(action);
        action.block();
    }

    public static void readResource(Resources res, int id, ByteArrayOutputStream output) {
        try {
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
        Resources res = webView.getResources();
        readResource(res, R.raw.transit, output);
        readResource(res, R.raw.runtime, output);
        return output.toString();
    }

    private void doInvokeNative(final Object _invocationDescription) {
        TransitJSObject invocationDescription = (TransitJSObject) _invocationDescription;

        final PreparedInvocation preparedInvocation;
        try {
            preparedInvocation = context.prepareInvoke(invocationDescription);
        } catch (Exception e) {
            pushAction(new TransitExceptionAction(e));
            return;
        }

        Executors.newSingleThreadExecutor().execute(new Runnable() {
            @Override
            public void run() {
                TransitAction action = null;

                try {
                    Log.d(TAG, String.format("Invoking native function `%s`", preparedInvocation.getFunction().getProxyId()));
                    Object resultObject = preparedInvocation.invoke();
                    String result = context.convertObjectToExpression(resultObject);
                    action = new TransitReturnResultAction(result);
                    Log.d(TAG, String.format("Native function `%s` returned `%s`", preparedInvocation.getFunction().getProxyId(), resultObject));
                } catch (Exception e) {
                    Log.e(TAG, String.format("%s threw an exception", preparedInvocation.getFunction()), e);
                    action = new TransitExceptionAction(e);
                } finally {
                    pushAction(action);
                }
            }
        });
    }

    private final Stack<TransitEvalAction> waitingEvaluations = new Stack<TransitEvalAction>();

    private void process(final JsPromptResult result) {
        runOnNonUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    TransitAction action = actions.takeFirst();

                    Log.d(TAG, String.format("Took %s from stack", action.getClass().getSimpleName()));

                    if (action instanceof TransitPollCompleteAction) {
                        assert isPolling();
                        
                        try {
                            end();
                            result.confirm();
                        } finally {
                            ((TransitPollCompleteAction) action).open();
                        }
                    } else if (action instanceof TransitReturnResultAction || action instanceof TransitExceptionAction) {
                        end();
                    } else if (action instanceof TransitEvalAction) {
                        waitingEvaluations.push((TransitEvalAction) action);
                    }

                    result.confirm(action.getJSRepresentation());
                } catch (InterruptedException e) {
                    panic(e);
                }
            }
        });
    }

    private void panic(Throwable e) {
        // TODO
    }

    private void begin() {
        begin(false);
    }

    private void begin(boolean polling) {
        if (!isActive()) {
            Log.i(TAG, String.format("begin(polling=%s)", polling));
            active = true;
        }
    }

    private void end() {
        if (isActive()) {
            Log.i(TAG, "end()");
            active = false;
            polling = false;
        }
    }

    private boolean isActive() {
        return active;
    }

    private boolean isPolling() {
        return polling;
    }
}

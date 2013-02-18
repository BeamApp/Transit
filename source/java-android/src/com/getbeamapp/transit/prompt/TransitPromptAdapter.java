package com.getbeamapp.transit.prompt;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
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
import android.webkit.WebView;

import com.getbeamapp.transit.AndroidTransitContext;
import com.getbeamapp.transit.JsonConverter;
import com.getbeamapp.transit.R;
import com.getbeamapp.transit.TransitAdapter;
import com.getbeamapp.transit.TransitContext.PreparedInvocation;
import com.getbeamapp.transit.TransitException;
import com.getbeamapp.transit.TransitJSObject;

public class TransitPromptAdapter implements TransitAdapter {

    enum TransitRequest {
        INVOKE("__TRANSIT_MAGIC_INVOKE"),
        POLL("__TRANSIT_MAGIC_POLL"),
        RETURN("__TRANSIT_MAGIC_RETURN"),
        EXCEPTION("__TRANSIT_MAGIC_EXCEPTION"),
        BATCH_INVOKE("__TRANSIT_MAGIC_BATCH_INVOKE");

        private String string;

        TransitRequest(String string) {
            assert (string != null);
            this.string = string;
        }

        public static TransitRequest fromString(String s) {
            for (TransitRequest r : TransitRequest.values()) {
                if (r.string.equals(s)) {
                    return r;
                }
            }

            return null;
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
    }

    public static final String TAG = "TransitAdapter";

    private final BlockingDeque<TransitAction> actions = new LinkedBlockingDeque<TransitAction>();

    final WebView webView;

    private AndroidTransitContext context;

    private boolean active = false;

    private boolean polling = false;

    public TransitPromptAdapter(WebView forWebView) {
        this.webView = forWebView;
        this.context = new AndroidTransitContext(this);
    }

    public final void initialize() {
        Log.d(TAG, "Injecting script...");
        this.active = false;
        this.polling = false;
        webView.loadUrl("javascript:" + getScript());
    }

    public static AndroidTransitContext createContext(WebView webView) {
        return createContext(webView, new TransitChromeClient());
    }

    public static AndroidTransitContext createContext(WebView webView, TransitChromeClient client) {
        TransitPromptAdapter adapter = new TransitPromptAdapter(webView);
        client.setTransitAdapter(adapter);
        webView.setWebChromeClient(client);
        return adapter.getContext();
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

    public boolean onJSCall(String requestType, String payload, TransitFuture<String> result) {

        Log.d(TAG, String.format("type: %s\npayload: %s", requestType, payload));
        final TransitRequest request = TransitRequest.fromString(requestType);

        if (request == null) {
            return false;
        }

        switch (request) {
        case POLL:
            assert !isActive();
            begin(true);
            process(result);
            break;
        case BATCH_INVOKE:
            assert !isActive();
            Object invocationsObject = unmarshal(payload);
            final List<?> invocations = (List<?>)invocationsObject;
            result.resolve();
            
            runOnNonUiThread(new Runnable() {
                @Override
                public void run() {
                    for(Object invocation : invocations) {
                        try {
                            doInvokeNativeAsync((TransitJSObject) context.proxify(invocation));
                        } catch (Exception e) {
                            Log.e(TAG, String.format("[%s] Invocation of `%s` failed", request, invocation));
                        }
                    }
                }
            });
            
            return true;
        case INVOKE:
            begin();
            doInvokeNative((TransitJSObject) context.proxify(unmarshal(payload)));
            process(result);
            break;
        case RETURN:
            assert isActive();
            TransitEvalAction actionToResolve = waitingEvaluations.pop();
            Object returnValue = context.proxify(unmarshal(payload));
            actionToResolve.resolveWith(returnValue);
            Log.d(TAG, String.format("[%s] %s -> %s", request, actionToResolve.getStringToEvaluate(), returnValue));
            process(result);
            break;
        case EXCEPTION:
            assert isActive();
            TransitEvalAction actionToReject = waitingEvaluations.pop();
            String error = String.valueOf(unmarshalJson(payload));
            actionToReject.rejectWith(error);
            Log.d(TAG, String.format("[%s] Rejected `%s` with `%s`", request, actionToReject.getStringToEvaluate(), error));
            process(result);
            break;
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
    
    protected void doInvokeNativeAsync(final TransitJSObject invocationDescription) {
        context.invoke(invocationDescription);
    }

    private void doInvokeNative(final TransitJSObject invocationDescription) {
        final PreparedInvocation preparedInvocation;
        try {
            preparedInvocation = context.prepareInvoke(invocationDescription);
        } catch (Exception e) {
            Log.e(TAG, "Failed to prepare invocation.", e);
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

    private void process(final TransitFuture<String> result) {
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
                            result.resolve();
                        } finally {
                            ((TransitPollCompleteAction) action).open();
                        }
                    } else if (action instanceof TransitReturnResultAction || action instanceof TransitExceptionAction) {
                        end();
                    } else if (action instanceof TransitEvalAction) {
                        waitingEvaluations.push((TransitEvalAction) action);
                    }

                    result.resolve(action.getJSRepresentation());
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

    public AndroidTransitContext getContext() {
        return context;
    }

}

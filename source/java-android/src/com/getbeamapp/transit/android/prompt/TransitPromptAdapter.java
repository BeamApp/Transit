package com.getbeamapp.transit.android.prompt;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Queue;
import java.util.Stack;
import java.util.concurrent.BlockingDeque;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingDeque;

import android.content.res.Resources;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.webkit.WebView;

import com.getbeamapp.transit.R;
import com.getbeamapp.transit.android.AndroidTransitContext;
import com.getbeamapp.transit.android.TransitAdapter;
import com.getbeamapp.transit.common.TransitException;
import com.getbeamapp.transit.common.TransitJSObject;
import com.getbeamapp.transit.common.TransitContext.PreparedInvocation;

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

    private final ExecutorService asyncThreadPool;

    private final ExecutorService genericThreadPool;

    private final Handler handler;

    private Queue<String> asyncEvaluations = new ConcurrentLinkedQueue<String>();

    private final Runnable consumeAsyncEvaluations;

    private Object notifiedUiThreadLock = new Object();

    private boolean notifiedUiThread = false;

    private boolean finalized = false;

    public TransitPromptAdapter(WebView forWebView) {
        this.webView = forWebView;
        this.context = new AndroidTransitContext(this);
        this.asyncThreadPool = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
        this.genericThreadPool = Executors.newCachedThreadPool();
        this.handler = new Handler(Looper.getMainLooper());
        this.consumeAsyncEvaluations = new Runnable() {

            @Override
            public void run() {
                if (webView == null || finalized) {
                    return;
                }

                synchronized (notifiedUiThreadLock) {
                    notifiedUiThread = false;
                }

                StringBuilder script = new StringBuilder();
                script.append("javascript:");

                boolean hasScripts = false;
                String current = null;

                while ((current = asyncEvaluations.poll()) != null) {
                    hasScripts = true;
                    script.append("try{");
                    script.append(current);
                    script.append("}catch(e){console.error(e)};");
                }

                if (hasScripts) {
                    webView.loadUrl(script.toString());
                }
            }

        };
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

    public Runnable wrapInvocation(final TransitJSObject invocation) {
        return new Runnable() {
            @Override
            public void run() {
                try {
                    doInvokeNativeAsync(invocation);
                } catch (Exception e) {
                    Log.e(TAG, String.format("[%s] Invocation of `%s` failed", TransitRequest.BATCH_INVOKE, invocation), e);
                }
            }
        };
    }

    private void doBatchInvoke(final String payload) {
        genericThreadPool.submit(new Runnable() {
            @Override
            public void run() {
                try {
                    for (Object invocation : context.lazyParse(payload)) {
                        assert invocation instanceof TransitJSObject;
                        asyncThreadPool.submit(wrapInvocation((TransitJSObject) invocation));
                    }
                } catch (Exception e) {
                    Log.e(TAG, "[%s] Batch invocation failed", e);
                }
            }
        });
    }

    public boolean onJSCall(final String requestType, final String payload, final TransitFuture<String> result) {

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
            assert payload.charAt(0) == '[';
            doBatchInvoke(payload);
            result.resolve();
            return true;
        case INVOKE:
            begin();
            doInvokeNative((TransitJSObject) context.parse(payload));
            process(result);
            break;
        case RETURN:
            assert isActive();
            TransitEvalAction actionToResolve = waitingEvaluations.pop();
            Object returnValue = context.parse(payload);
            actionToResolve.resolveWith(returnValue);
            Log.d(TAG, String.format("[%s] %s -> %s", request, actionToResolve.getStringToEvaluate(), returnValue));
            process(result);
            break;
        case EXCEPTION:
            assert isActive();
            TransitEvalAction actionToReject = waitingEvaluations.pop();
            String error = String.valueOf(context.parse(payload));
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

    protected void ensureOnUiThread(Runnable runnable) {
        if (isUiThread()) {
            runnable.run();
        } else {
            handler.postDelayed(runnable, 1L);
        }
    }

    protected void ensureOnNonUiThread(Runnable runnable) {
        if (isUiThread()) {
            genericThreadPool.submit(runnable);
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
        evaluateAsync("transit.releaseElementWithId(\"" + proxyId + "\")");
    }

    @Override
    public final void evaluateAsync(final String stringToEvaluate) {
        Log.d(TAG, "evaluateAsync: " + stringToEvaluate);
        
        asyncEvaluations.add(stringToEvaluate);
        
        boolean mustNotify = false;
        synchronized (notifiedUiThreadLock) {
            mustNotify = !notifiedUiThread;

            if (!notifiedUiThread) {
                notifiedUiThread = true;
            }
        }

        if (mustNotify) {
            ensureOnUiThread(consumeAsyncEvaluations);
        }
    }

    @Override
    protected void finalize() throws Throwable {
        this.finalized = true;
        super.finalize();
    }

    public final Object evaluate(String stringToEvaluate) {
        Log.d(TAG, "evaluate: " + stringToEvaluate);
        
        // TODO: Make sure no "outside" evaluate-calls cause conflicts with
        // active Transit threads

        boolean mustInitPoll = !isActive();
        
        if (mustInitPoll && isUiThread()) {
            throw new IllegalThreadStateException("Can't call (initial) blocking eval from UI thread.");
        }

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
        evaluateAsync("transit.poll()");
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
        Log.d(TAG, String.format("Invoke native function with id: `%s`", invocationDescription.get("nativeId")));
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

        genericThreadPool.submit(new Runnable() {
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
        genericThreadPool.submit(new Runnable() {
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

    private void begin(boolean _polling) {
        if (!isActive()) {
            this.active = true;
            this.polling = _polling;
            Log.i(TAG, String.format("begin(polling=%s)", this.polling));
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

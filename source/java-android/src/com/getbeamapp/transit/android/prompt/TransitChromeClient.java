package com.getbeamapp.transit.android.prompt;

import android.util.Log;
import android.webkit.ConsoleMessage;
import android.webkit.JsPromptResult;
import android.webkit.WebChromeClient;
import android.webkit.WebView;

public class TransitChromeClient extends WebChromeClient {

    private static final String TAG = TransitChromeClient.class.getSimpleName();

    private TransitPromptAdapter transitAdapter;

    public TransitChromeClient() {

    }

    public TransitPromptAdapter getTransitAdapter() {
        return transitAdapter;
    }

    public void setTransitAdapter(TransitPromptAdapter transitAdapter) {
        this.transitAdapter = transitAdapter;
    }

    @Override
    public boolean onJsPrompt(WebView view, String url, String message, String defaultValue, JsPromptResult result) {
        TransitFuture<String> future = new TransitFuture<String>();

        if (transitAdapter.onJSCall(message, defaultValue, future)) {
            result.confirm(future.block());
            return true;
        } else {
            return super.onJsPrompt(view, url, message, defaultValue, result);
        }
    }

    @Override
    public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
        switch (consoleMessage.messageLevel()) {
        case ERROR:
            Log.e(TAG, consoleMessage.message());
            break;
        case WARNING:
            Log.w(TAG, consoleMessage.message());
            break;
        case DEBUG:
            Log.d(TAG, consoleMessage.message());
            break;
        case TIP:
        case LOG:
        default:
            Log.i(TAG, consoleMessage.message());
        }

        return true;
    }
}

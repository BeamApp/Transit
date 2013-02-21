package com.getbeamapp.transit.prompt;

import android.webkit.JsPromptResult;
import android.webkit.WebChromeClient;
import android.webkit.WebView;

public class TransitChromeClient extends WebChromeClient {

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
}

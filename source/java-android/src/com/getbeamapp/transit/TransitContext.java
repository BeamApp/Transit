package com.getbeamapp.transit;

import android.webkit.WebView;

public class TransitContext extends AbstractTransitContext {

    private final TransitWebChromeClient adapter;

    private TransitContext(TransitWebChromeClient adapter) {
        this.adapter = adapter;
        adapter.setTransitContext(this);
    }

    public static TransitContext forWebView(WebView webView) {
        return forWebView(webView, new TransitWebChromeClient(webView));
    }

    public TransitWebChromeClient getAdapter() {
        return this.adapter;
    }

    @Override
    public TransitProxy eval(String stringToEvaluate, TransitProxy context,
            Object... arguments) {
        return adapter.evaluate(stringToEvaluate);
    }

    public static TransitContext forWebView(WebView webView,
            TransitWebChromeClient adapter) {
        assert webView == adapter.webView;
        webView.setWebChromeClient(adapter);
        return new TransitContext(adapter);
    }

}

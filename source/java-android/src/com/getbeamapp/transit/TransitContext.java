package com.getbeamapp.transit;

import android.webkit.WebView;

public class TransitContext extends AbstractTransitContext {

    private final TransitAdapter adapter;

    public TransitContext(TransitAdapter adapter) {
        this.adapter = adapter;
    }

    public TransitAdapter getAdapter() {
        return this.adapter;
    }

    @Override
    public TransitProxy eval(String stringToEvaluate, TransitProxy context,
            Object... arguments) {
        return adapter.evaluate(stringToEvaluate);
    }

    public static TransitContext forWebView(WebView webView,
            TransitAdapter adapter) {
        return new TransitContext(adapter);
    }

}

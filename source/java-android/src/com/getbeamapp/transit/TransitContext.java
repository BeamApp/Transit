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
    public TransitProxy evalWithContext(String stringToEvaluate, Object context,
            Object... arguments) {

        if (context == null) {
            context = this;
        }

        TransitProxy[] proxifiedArguments = new TransitProxy[arguments.length];

        for (int i = 0; i < arguments.length; i++) {
            proxifiedArguments[i] = TransitProxy.withValue(this, arguments[i]);
        }

        return adapter.evaluate(stringToEvaluate, TransitProxy.withValue(this, context), proxifiedArguments);
    }

    public static TransitContext forWebView(WebView webView,
            TransitAdapter adapter) {
        return new TransitContext(adapter);
    }

    @Override
    public String getJavaScriptRepresentation() {
        return "window";
    }
}

package com.getbeamapp.transit;

import android.webkit.WebView;

public class AndroidTransitContext extends TransitContext {

    private final TransitAdapter adapter;

    public AndroidTransitContext(TransitAdapter adapter) {
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
            proxifiedArguments[i] = proxify(arguments[i]);
        }

        return adapter.evaluate(stringToEvaluate, proxify(context), proxifiedArguments);
    }

    public static AndroidTransitContext forWebView(WebView webView,
            TransitAdapter adapter) {
        return new AndroidTransitContext(adapter);
    }

    @Override
    public String getJavaScriptRepresentation() {
        return "window";
    }
}

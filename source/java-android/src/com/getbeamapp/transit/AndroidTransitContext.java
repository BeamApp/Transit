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
    public Object evalWithThisArg(String stringToEvaluate, Object thisArg,
            Object... arguments) {
        String expression = jsExpressionFromCodeWithThis(stringToEvaluate, thisArg, arguments);
        return adapter.evaluate(expression);
    }

    public static AndroidTransitContext forWebView(WebView webView, TransitAdapter adapter) {
        return new AndroidTransitContext(adapter);
    }

    @Override
    public void releaseProxy(String id) {
        adapter.releaseProxy(id);
    }
}

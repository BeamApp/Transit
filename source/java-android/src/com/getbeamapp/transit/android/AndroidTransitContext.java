package com.getbeamapp.transit.android;

import com.getbeamapp.transit.common.TransitContext;

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
            Object... values) {
        String expression = jsExpressionFromCodeWithThis(stringToEvaluate, thisArg, values);
        return adapter.evaluate(expression);
    }
    
    @Override
    public void evalWithThisArgAsync(String stringToEvaluate, Object thisArg, Object... values) {
        String expression = jsExpressionFromCodeWithThis(stringToEvaluate, thisArg, values);
        adapter.evaluateAsync(expression);
    }

    public static AndroidTransitContext forWebView(WebView webView, TransitAdapter adapter) {
        return new AndroidTransitContext(adapter);
    }

    @Override
    public void releaseProxy(String id) {
        if(adapter != null) {
            adapter.releaseProxy(id);
        }
    }
}

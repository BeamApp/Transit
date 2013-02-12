package com.getbeamapp.transit;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

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

        if (context == null) {
            context = this;
        }

        List<Object> newArgs = new LinkedList<Object>();
        newArgs.add(context);
        newArgs.addAll(Arrays.asList(arguments));
        Object[] newArgsArray = newArgs.toArray(new Object[newArgs.size()]);
        return adapter.evaluate(TransitProxy.jsExpressionFromCode(stringToEvaluate, newArgsArray));
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

package com.getbeamapp.transit;

import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;
import java.util.concurrent.Executors;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.webkit.ConsoleMessage;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.getbeamapp.transit.prompt.TransitChromeClient;

public class BenchmarkActivity extends Activity {

    public AndroidTransitContext transit;
    public WebView webView;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        webView = new WebView(this);
        webView.getSettings().setJavaScriptEnabled(true);

        this.transit = TransitChromeClient.createContext(webView, new TransitChromeClient(webView) {
            @Override
            public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
                Log.d("Console", consoleMessage.message());
                return true;
            }
        });

        webView.setWebViewClient(new WebViewClient());
        transit.getAdapter().initialize();

        final TransitNativeFunction pingBlocked = transit.registerCallable(new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                return null;
            }
        });

        final TransitNativeFunction ping = transit.registerCallable(new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                TransitJSFunction cb = (TransitJSFunction) arguments[1];
                cb.call();
                return null;
            }
        });

        ByteArrayOutputStream htmlDocument = new ByteArrayOutputStream();
        TransitChromeClient.readResource(getResources(), R.raw.benchmark, htmlDocument);
        try {
            String document = htmlDocument.toString("utf-8");
            webView.loadDataWithBaseURL(null, document, "text/html", "utf-8", null);
        } catch (UnsupportedEncodingException e1) {
            Log.e("TransitAdapter", "E", e1);
        }
        setContentView(webView);

        Executors.newSingleThreadExecutor().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    transit.eval("window.forge = { internal: { ping: @, pingBlocked: @ } }", ping, pingBlocked);
                } catch (Exception e) {
                    Log.d("TransitAdapter", "Failed", e);
                }
            }
        });
    }

}

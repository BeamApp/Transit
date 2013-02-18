package com.getbeamapp.transit;

import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;
import java.util.EnumSet;
import java.util.concurrent.Executors;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.webkit.ConsoleMessage;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.getbeamapp.transit.TransitCallable.Flags;
import com.getbeamapp.transit.prompt.TransitChromeClient;
import com.getbeamapp.transit.prompt.TransitPromptAdapter;

public class BenchmarkActivity extends Activity {

    public AndroidTransitContext transit;
    public WebView webView;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        webView = new WebView(this);
        webView.getSettings().setJavaScriptEnabled(true);

        this.transit = TransitPromptAdapter.createContext(webView, new TransitChromeClient() {
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
        }, EnumSet.of(Flags.ASYNC));

        ByteArrayOutputStream htmlDocument = new ByteArrayOutputStream();
        TransitPromptAdapter.readResource(getResources(), R.raw.benchmark, htmlDocument);
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

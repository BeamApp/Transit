package com.getbeamapp.transit;

import java.util.concurrent.Executors;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.webkit.ConsoleMessage;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {

    public TransitContext transit;
    public WebView webView;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        webView = new WebView(this);
        webView.getSettings().setJavaScriptEnabled(true);

        this.transit = TransitContext.forWebView(webView, new TransitWebChromeClient(webView) {
            @Override
            public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
                Log.d("Console", consoleMessage.message());
                return true;
            }
        });

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onReceivedError(WebView view, int errorCode,
                    String description, String failingUrl) {
                Log.e("Console", "Error received.");
            }
        });

        webView.loadUrl("javascript:" + transit.getAdapter().getScript());

        webView.loadData(
                "<html><head><title>Transit</title></head><body>Hello World!</body></html>",
                "text/html", null);

        setContentView(webView);

        Executors.newSingleThreadExecutor().execute(new Runnable() {
            @Override
            public void run() {
                Log.i("DEBUG", transit.toString());
                return;
            }
        });
    }

}

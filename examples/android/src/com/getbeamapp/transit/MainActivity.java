package com.getbeamapp.transit;

import java.util.concurrent.Executors;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.webkit.ConsoleMessage;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

public class MainActivity extends Activity {

	public TransitWebChromeClient transit;
	public WebView webView;

	@SuppressLint("SetJavaScriptEnabled")
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		webView = new WebView(this);
		webView.getSettings().setJavaScriptEnabled(true);

		transit = new TransitWebChromeClient(this, webView) {
			@Override
			public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
				Log.d("Console", consoleMessage.message());
				return true;
			}
		};

		webView.setWebChromeClient(transit);

		webView.setWebViewClient(new WebViewClient() {
			@Override
			public void onReceivedError(WebView view, int errorCode,
					String description, String failingUrl) {
				Log.d("MainActivity", "Error received.");
			}
		});
		
		webView.loadData(
				"<html><head><title>Transit</title></head><body>Hello World!</body></html>",
				"text/html", null);

		setContentView(webView);
	}

}

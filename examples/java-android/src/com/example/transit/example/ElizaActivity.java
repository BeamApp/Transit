package com.example.transit.example;

import java.io.ByteArrayOutputStream;
import java.util.concurrent.Executors;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.NavUtils;
import android.view.KeyEvent;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.inputmethod.EditorInfo;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;
import android.widget.Toast;

import com.getbeamapp.transit.android.AndroidTransitContext;
import com.getbeamapp.transit.android.prompt.TransitChromeClient;
import com.getbeamapp.transit.android.prompt.TransitPromptAdapter;
import com.getbeamapp.transit.common.TransitProxy;

@SuppressLint("SetJavaScriptEnabled")
public class ElizaActivity extends FragmentActivity {

    private static final String TAG = ElizaActivity.class.getSimpleName();
    
    private AndroidTransitContext transit;
    private WebView webView;
    private TransitProxy elizaBot;
    private String elizaScript;
    private EditText input;
    private ListView chat;
    private ChatArrayAdapter chatAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_eliza);
        getActionBar().setDisplayHomeAsUpEnabled(true);
        
        chatAdapter = new ChatArrayAdapter(this, R.layout.fragment_chatmessage);
        input = (EditText) findViewById(R.id.eliza_input);
        chat = (ListView) findViewById(R.id.eliza_chat);
        chat.setAdapter(chatAdapter);
        chat.setTranscriptMode(ListView.TRANSCRIPT_MODE_ALWAYS_SCROLL);
        chat.setStackFromBottom(true);

        webView = (WebView) findViewById(R.id.eliza_webview);
        webView.getSettings().setJavaScriptEnabled(true);

        setupTransit();
        webView.loadDataWithBaseURL("http://somewhere", "", "text/html", "utf-8", null);

        ByteArrayOutputStream elizaScriptStream = new ByteArrayOutputStream();
        TransitPromptAdapter.readResource(getResources(), R.raw.eliza_data, elizaScriptStream);
        elizaScriptStream.write((int) '\n');
        TransitPromptAdapter.readResource(getResources(), R.raw.elizabot, elizaScriptStream);
        elizaScript = elizaScriptStream.toString();

        Button btn = (Button) findViewById(R.id.eliza_send_button);
        btn.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                onSubmit();
            }
        });
        
        input.setOnEditorActionListener(new OnEditorActionListener() {            
            @Override
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                if (actionId == EditorInfo.IME_NULL && event.getAction() == KeyEvent.ACTION_DOWN) {
                    onSubmit();
                    return true;
                }
                
                return false;
            }
        });
    }
    
    private void onSubmit() {
        final String text = input.getText().toString();
        
        if (text.trim().isEmpty()) {
            return;
        }
        
        pushUserMessage(text);
        input.setText("");
        
        Executors.newSingleThreadExecutor().execute(new Runnable() {
            @Override
            public void run() {
                String response = (String) elizaBot.callMember("transform", text);
                pushElizaMessage(response);
            }
        });
    }
    
    private void pushUserMessage(final String text) {
        chatAdapter.add(new ChatMessage(text, true));
    }
    
    private void pushElizaMessage(final String text) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                chatAdapter.add(new ChatMessage(text, false));
            }
        });
    }

    private void setupTransit() {
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {

                transit.getAdapter().initialize();
                webView.loadUrl("javascript:" + elizaScript);

                Executors.newSingleThreadExecutor().execute(new Runnable() {
                    @Override
                    public void run() {
                        elizaBot = (TransitProxy) transit.eval("new ElizaBot()");
                        String initialMessage = (String) elizaBot.callMember("getInitial");
                        pushElizaMessage(initialMessage);
                    }
                });
                super.onPageStarted(view, url, favicon);
            }
        });

        transit = TransitPromptAdapter.createContext(webView, new TransitChromeClient());
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
        case android.R.id.home:
            // This ID represents the Home or Up button. In the case of this
            // activity, the Up button is shown. Use NavUtils to allow users
            // to navigate up one level in the application structure. For
            // more details, see the Navigation pattern on Android Design:
            //
            // http://developer.android.com/design/patterns/navigation.html#up-vs-back
            //
            NavUtils.navigateUpTo(this, new Intent(this, ExampleListActivity.class));
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
}

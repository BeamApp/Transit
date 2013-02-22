package com.example.transit.example;

import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.Executors;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.Intent;
import android.graphics.Bitmap;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.os.Build;
import android.os.Bundle;
import android.os.Vibrator;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.NavUtils;
import android.view.MenuItem;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.getbeamapp.transit.android.AndroidTransitContext;
import com.getbeamapp.transit.android.prompt.TransitChromeClient;
import com.getbeamapp.transit.android.prompt.TransitPromptAdapter;
import com.getbeamapp.transit.common.TransitJSFunction;
import com.getbeamapp.transit.common.TransitReplacementCallable;

/**
 * An activity representing a single Example detail screen. This activity is
 * only used on handset devices. On tablet-size devices, item details are
 * presented side-by-side with a list of items in a {@link ExampleListActivity}.
 * <p>
 * This activity is mostly just a 'shell' activity containing nothing more than
 * a {@link ExampleDetailFragment}.
 */
@SuppressLint("SetJavaScriptEnabled")
public class ExampleDetailActivity extends FragmentActivity {

    private static final String TAG = ExampleDetailActivity.class.getCanonicalName();
    
    private static final String URL = "http://phoboslab.org/xtype/";

    private SoundPool soundPool;
    private int explosionSoundId;
    private AudioManager audioManager;
    private AndroidTransitContext transit;
    private WebView webView;

    private Vibrator vibrator;

    private long lastShot;

    private MediaPlayer musicMediaPlayer;

    private MediaPlayer shootingMediaPlayer;

    private Timer timer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_example_detail);

        // Show the Up button in the action bar.
        getActionBar().setDisplayHomeAsUpEnabled(true);

        setVolumeControlStream(AudioManager.STREAM_MUSIC);

        vibrator = (Vibrator) getSystemService(VIBRATOR_SERVICE);

        webView = (WebView) findViewById(R.id.xtype_webview);
        webView.getSettings().setJavaScriptEnabled(true);
        
        audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
        loadSounds();
        setupTransit();
        webView.loadUrl(URL);
    }

    private void loadSounds() {
        musicMediaPlayer = MediaPlayer.create(this, R.raw.xtype);
        musicMediaPlayer.setLooping(true);
        musicMediaPlayer.setVolume(0.4f, 0.4f);
        
        shootingMediaPlayer = MediaPlayer.create(this, R.raw.plasma_burst);
        shootingMediaPlayer.setLooping(true);
        
        soundPool = new SoundPool(10, AudioManager.STREAM_MUSIC, 0);
        explosionSoundId = soundPool.load(this, R.raw.explosion, 0);
        
        timer = new Timer();
        timer.schedule(new TimerTask() {
            
            @Override
            public void run() {
                if (shootingMediaPlayer.isPlaying()) {
                    if (System.currentTimeMillis() > lastShot + 100) {
                       shootingMediaPlayer.pause(); 
                    }
                }
            }
            
        }, 0, 100);
    }

    private void setupTransit() {
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                if (url.equals(URL)) {
                    transit.getAdapter().initialize();

                    Executors.newSingleThreadExecutor().execute(new Runnable() {
                        @Override
                        public void run() {
                            setupHooks();
                        }
                    });
                }

                super.onPageStarted(view, url, favicon);
            }
        });

        transit = TransitPromptAdapter.createContext(webView, new TransitChromeClient());
    }

    private void setupHooks() {
        transit.replaceFunctionAsync("window.setTimeout", new TransitReplacementCallable() {

            private boolean called = false;

            @Override
            public Object evaluate(TransitJSFunction setTimeout, Object thisArg, Object... arguments) {
                if (called) {
                    return setTimeout.callWithThisArg(thisArg, arguments);
                }

                transit.replaceFunction("ig.Sound.prototype.play", new TransitReplacementCallable() {
                    @Override
                    public Object evaluate(TransitJSFunction original, Object thisArg, Object... arguments) {
                        soundPool.play(explosionSoundId, 1, 1, 0, 0, 1);
                        return true;
                    }
                });

                transit.replaceFunction("ig.Music.prototype.play", new TransitReplacementCallable() {
                    @Override
                    public Object evaluate(TransitJSFunction original, Object thisArg, Object... arguments) {
                        musicMediaPlayer.start();
                        return true;
                    }
                });

                transit.replaceFunction("EntityPlayer.prototype.shoot", new TransitReplacementCallable() {
                    @Override
                    public Object evaluate(TransitJSFunction original, Object thisArg, Object... arguments) {
                        lastShot = System.currentTimeMillis();
                        
                        if (!shootingMediaPlayer.isPlaying()) {
                            shootingMediaPlayer.start();
                        }
                        
                        return original.callWithThisArg(thisArg, arguments);
                    }
                });

                TransitReplacementCallable vibrate = new TransitReplacementCallable() {
                    @Override
                    public Object evaluate(TransitJSFunction original, Object thisArg, Object... arguments) {
                        vibrator.vibrate(150);
                        return original.callWithThisArg(thisArg, arguments);
                    }
                };

                transit.replaceFunction("EntityEnemyHeart.prototype.kill", vibrate);
                transit.replaceFunction("EntityPlayer.prototype.kill", vibrate);

                transit.eval("window.setTimeout = @", setTimeout);
                return setTimeout.callWithThisArg(thisArg, arguments);
            }
        });
    }
    
    @TargetApi(Build.VERSION_CODES.JELLY_BEAN)
    @Override
    public boolean onNavigateUp() {
        onPause();
        return super.onNavigateUp();
    }
    
    @Override
    protected void onPause() {
        webView.onPause();
        musicMediaPlayer.stop();
        shootingMediaPlayer.stop();
        soundPool.autoPause();
        super.onPause();
    }
    
    @Override
    protected void onResume() {
        webView.onResume();
        soundPool.autoResume();
        super.onResume();
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

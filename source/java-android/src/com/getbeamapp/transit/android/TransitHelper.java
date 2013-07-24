package com.getbeamapp.transit.android;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

public final class TransitHelper {

    private static final String TAG = TransitHelper.class.getCanonicalName();

	private TransitHelper() {
        // not meant for instantiation
	}

	public static Thread getUiThread() {
		return Looper.getMainLooper().getThread();
	}

	public static boolean isUiThread() {
		return Thread.currentThread() == getUiThread();
	}

	public static void runOnUiThread(Runnable r) {
		if (isUiThread()) {
            try {
			    r.run();
            } catch (Exception e) {
                Log.e(TAG, "runOnUiThread", e);
            }
		} else {
			Handler handler = new Handler(Looper.getMainLooper());
			handler.post(r);
		}
	}

	private static final ExecutorService nonUiExecutor = Executors.newSingleThreadExecutor();

	public static void runOnNonUiThread(Runnable r) {
		if (isUiThread()) {
			nonUiExecutor.execute(r);
		} else {
            try {
			    r.run();
            } catch (Exception e) {
                Log.e(TAG, "runOnNonUiThread", e);
            }
		}
	}
}

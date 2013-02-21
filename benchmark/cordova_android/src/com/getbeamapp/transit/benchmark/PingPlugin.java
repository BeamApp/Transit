package com.getbeamapp.transit.benchmark;

import org.apache.cordova.api.Plugin;
import org.apache.cordova.api.PluginResult;
import org.apache.cordova.api.PluginResult.Status;
import org.json.JSONArray;

@SuppressWarnings("deprecation")
public class PingPlugin extends Plugin {

	@Override
	public PluginResult execute(String arg0, JSONArray data, String arg2) {
		PluginResult result = new PluginResult(Status.OK, data);
		return result;
	}

}

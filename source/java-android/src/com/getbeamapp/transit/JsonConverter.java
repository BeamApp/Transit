package com.getbeamapp.transit;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.json.JSONArray;
import org.json.JSONObject;

public final class JsonConverter {
    
    public static Object toNative(Object o) {
        if(o instanceof JSONObject) {
            return toNativeMap((JSONObject) o);
        } else if (o instanceof JSONArray) {
            return toNativeList((JSONArray) o);
        } else {
            return o;
        }
    }
    
    @SuppressWarnings("rawtypes")
    public static Map<String, Object> toNativeMap(JSONObject o) {
        Map<String, Object> map = new HashMap<String, Object>();
        Iterator i = o.keys();
        
        while(i.hasNext()) {
            String key = (String)i.next();
            Object v = o.opt(key);
            map.put(key, toNative(v));
        }
        
        return map;
    }
    
    public static List<Object> toNativeList(JSONArray array) {
        List<Object> result = new ArrayList<Object>(array.length());
        
        for(int i = 0; i < array.length(); i++) {
            result.add(toNative(array.opt(i)));
        }
        
        return result;
    }
}

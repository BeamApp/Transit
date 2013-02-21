package com.getbeamapp.transit.common;

import java.util.HashMap;
import java.util.List;

public class TransitJSObject extends HashMap<String, Object> {

    private static final long serialVersionUID = 157261856618747426L;

    public List<?> getArray(String key) {
        return ((List<?>) get(key));
    }

}

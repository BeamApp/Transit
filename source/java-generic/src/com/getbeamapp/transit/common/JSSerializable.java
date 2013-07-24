package com.getbeamapp.transit.common;

import java.util.HashMap;
import java.util.Map;

public interface JSSerializable {
    public Map<?, ?> toJSObject();
}

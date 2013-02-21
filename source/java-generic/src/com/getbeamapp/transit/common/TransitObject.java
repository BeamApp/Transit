package com.getbeamapp.transit.common;


public abstract class TransitObject {
    
    public abstract TransitContext getContext();
    
    public Object get(String key) {
        return getContext().eval("@[@]", this, key);
    }

    public Object callMember(String key, Object... arguments) {
        return getContext().eval("@[@].apply(@, @)", this, key, this, arguments);
    }
    
}

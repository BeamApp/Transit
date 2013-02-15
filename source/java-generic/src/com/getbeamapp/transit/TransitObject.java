package com.getbeamapp.transit;

public abstract class TransitObject {
    
    public abstract TransitContext getRootContext();
    
    public Object get(String key) {
        return getRootContext().eval("@[@]", this, key);
    }

    public Object callMember(String key, Object... arguments) {
        return getRootContext().eval("@[@].apply(@, @)", this, key, this, arguments);
    }
    
}

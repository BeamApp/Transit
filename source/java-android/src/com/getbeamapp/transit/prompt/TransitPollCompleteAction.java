package com.getbeamapp.transit.prompt;

import android.os.ConditionVariable;


class TransitPollCompleteAction extends TransitAction {
    
    private ConditionVariable lock = new ConditionVariable(false);
    
    @Override
    public String getJSRepresentation() {
        return "null";
    }
    
    public void block() {
        lock.block();
    }
    
    public void open() {
        lock.open();
    }
}

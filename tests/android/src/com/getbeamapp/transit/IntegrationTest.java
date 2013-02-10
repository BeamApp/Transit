package com.getbeamapp.transit;

import com.getbeamapp.transit.prompt.TransitChromeClient;

import android.test.ActivityInstrumentationTestCase2;

public class IntegrationTest extends ActivityInstrumentationTestCase2<MainActivity> {
    public IntegrationTest() {
        super(MainActivity.class);
    }
    
    public void testAllSetup() {
        MainActivity activity = getActivity();
        assertNotNull(activity);

        TransitContext transit = activity.transit;
        assertNotNull(transit);
        assertNotNull(transit.getAdapter());

        TransitChromeClient adapter = (TransitChromeClient)transit.getAdapter();
        assertNotNull(adapter.getScript());
    }

    public void testTransitInjected() {
        TransitProxy transitExists = getActivity().transit.eval("window.transit != null");
        assertEquals(true, (boolean) transitExists.getBooleanValue());
    }

    public void testException() {
        try {
            getActivity().transit.eval("(void 0).toString()");
            fail();
        } catch (TransitException e) {
            assertEquals("Cannot call method 'toString' of undefined", e.getMessage());
        }
    }
    
    public void testOperationAdd() {
        assertEquals(4, (int) getActivity().transit.eval("2 + 2").getIntegerValue());
    }
}

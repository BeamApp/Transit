package com.getbeamapp.transit;

import android.test.ActivityInstrumentationTestCase2;

import com.getbeamapp.transit.prompt.TransitChromeClient;

public class IntegrationTest extends ActivityInstrumentationTestCase2<MainActivity> {

    public final long TIMEOUT = 1000L;

    public IntegrationTest() {
        super(MainActivity.class);
    }

    public void testAllSetup() {
        MainActivity activity = getActivity();
        assertNotNull(activity);

        TransitContext transit = activity.transit;
        assertNotNull(transit);
        assertNotNull(transit.getAdapter());

        TransitChromeClient adapter = (TransitChromeClient) transit.getAdapter();
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
            assertEquals("TypeError: Cannot call method 'toString' of undefined", e.getMessage());
        }
    }

    public void testOperationAdd() {
        assertEquals(4, (int) getActivity().transit.eval("2 + 2").getIntegerValue());
    }

    public void testNativeFunction() {
        final boolean[] called = new boolean[] { false };
        
        TransitContext transit = getActivity().transit;
        TransitCallable callable = new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                called[0] = true;
                return null;
            }
        };

        TransitNativeFunction function = transit.registerCallable(callable);
        transit.eval("@()", function);

        assertTrue("Native function not called.", called[0]);
    }
}

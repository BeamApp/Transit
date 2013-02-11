package com.getbeamapp.transit;

import com.getbeamapp.transit.prompt.TransitChromeClient;

import android.os.ConditionVariable;
import android.test.ActivityInstrumentationTestCase2;

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
        final ConditionVariable lock = new ConditionVariable();

        TransitContext transit = getActivity().transit;
        TransitCallable callable = new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                lock.open();
                return null;
            }
        };

        TransitNativeFunction function = transit.registerCallable(callable);
        transit.eval("@()", function);

        assertTrue("Native function not called.", lock.block(TIMEOUT));
    }
}

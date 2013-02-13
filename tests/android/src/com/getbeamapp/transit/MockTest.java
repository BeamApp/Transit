package com.getbeamapp.transit;

import junit.framework.TestCase;

import com.google.android.testing.mocking.AndroidMock;
import com.google.android.testing.mocking.UsesMocks;

@UsesMocks(value = { AndroidTransitContext.class, TransitAdapter.class })
public class MockTest extends TestCase {

    private final TransitCallable noop;
    private final TransitAdapter noopAdapter;

    class NoopAdapter implements TransitAdapter {

        @Override
        public void initialize() {
            noop.evaluate(null);
        }

        @Override
        public TransitProxy evaluate(String stringToEvaluate, JavaScriptRepresentable thisArg, JavaScriptRepresentable... arguments) {
            return null;
        }

        @Override
        public void releaseProxy(String proxyId) {
            return;
        }

    }

    public MockTest() {
        this.noop = new TransitCallable() {
            @Override
            public Object evaluate(TransitProxy thisArg, TransitProxy... arguments) {
                return null;
            }
        };

        this.noopAdapter = new TransitAdapter() {

            @Override
            public void initialize() {
                noop.evaluate(null);
            }

            @Override
            public TransitProxy evaluate(String stringToEvaluate, JavaScriptRepresentable thisArg, JavaScriptRepresentable... arguments) {
                return null;
            }

            @Override
            public void releaseProxy(String proxyId) {
                return;
            }

        };
    }

    public void testMockLibrary() {
        TransitProxy proxy = AndroidMock.createMock(AndroidTransitContext.class, noopAdapter);
        AndroidMock.expect(proxy.get()).andReturn(42);
        AndroidMock.expect(proxy.get()).andReturn(42);
        AndroidMock.replay(proxy);
        assertEquals(42, proxy.get());

        try {
            AndroidMock.verify(proxy);
            fail();
        } catch (AssertionError e) {
            // WORKAROUND: EasyMock creates oddly formatted messages with
            // newlines and tabs - let's get rid of multiple whitespace chars.
            String msg = e.getMessage().trim().replaceAll("[\\r\\n\\s\\t]+", " ");
            assertEquals("Expectation failure on verify: get(): expected: 2, actual: 1", msg);
        }
    }

    public void testProxyRelase() throws InterruptedException {
        TransitAdapter adapter = AndroidMock.createNiceMock(TransitAdapter.class);
        adapter.releaseProxy("1");
        AndroidMock.expectLastCall();
        AndroidMock.replay(adapter);

        AndroidTransitContext ctx = new AndroidTransitContext(adapter);
        
        ctx.proxify("__TRANSIT_JS_FUNCTION_1");
        System.gc();
        AndroidMock.verify(adapter);
    }
}

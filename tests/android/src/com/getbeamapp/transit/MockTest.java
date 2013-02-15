package com.getbeamapp.transit;

import junit.framework.TestCase;

import com.google.android.testing.mocking.AndroidMock;
import com.google.android.testing.mocking.UsesMocks;

@UsesMocks(value = { TransitJSObject.class, TransitAdapter.class })
public class MockTest extends TestCase {

    public void testMockLibrary() {
        TransitJSObject proxy = AndroidMock.createMock(TransitJSObject.class);
        AndroidMock.expect(proxy.get("answer")).andReturn("42");
        AndroidMock.expect(proxy.get("answer")).andReturn("42");
        AndroidMock.replay(proxy);
        assertEquals("42", proxy.get("answer"));

        try {
            AndroidMock.verify(proxy);
            fail();
        } catch (AssertionError e) {
            // WORKAROUND: EasyMock creates oddly formatted messages with
            // newlines and tabs - let's get rid of multiple whitespace chars.
            String msg = TestHelpers.reduceWhitespace(e.getMessage());
            assertEquals("Expectation failure on verify: get(): expected: 2, actual: 1", msg);
        }
    }

    public void testProxyRelase() throws InterruptedException {
        TransitAdapter adapter = AndroidMock.createNiceMock(TransitAdapter.class);
        adapter.releaseProxy("1");
        AndroidMock.replay(adapter);

        AndroidTransitContext ctx = new AndroidTransitContext(adapter);

        ctx.proxify("__TRANSIT_JS_FUNCTION_1");
        System.gc();
        AndroidMock.verify(adapter);
    }

}

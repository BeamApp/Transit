package com.getbeamapp.transit;

import static com.getbeamapp.transit.Matchers.contains;
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
            assertEquals("Expectation failure on verify: get(\"answer\"): expected: 2, actual: 1", msg);
        }
    }

    public void testProxyRelase() throws InterruptedException {
        TransitAdapter adapter = AndroidMock.createNiceMock(TransitAdapter.class);
        adapter.releaseProxy("1");
        AndroidMock.replay(adapter);

        AndroidTransitContext ctx = new AndroidTransitContext(adapter);

        ctx.parse("\"__TRANSIT_JS_FUNCTION_1\"");
        System.gc();
        Thread.yield();
        AndroidMock.verify(adapter);
    }

    public void testTransitObject() {
        TransitAdapter adapter = AndroidMock.createMock(TransitAdapter.class);
        AndroidMock.expect(adapter.evaluate("window[\"title\"]")).andReturn("Untitled");
        AndroidMock.expect(adapter.evaluate("window[\"alert\"].apply(window, [42])")).andReturn(true);
        AndroidMock.replay(adapter);

        AndroidTransitContext ctx = new AndroidTransitContext(adapter);
        Object title = ctx.get("title");
        Object alertResult = ctx.callMember("alert", 42);

        AndroidMock.verify(adapter);
        assertEquals("Untitled", title);
        assertEquals(true, alertResult);
    }

    public void testJSFunction() {
        TransitAdapter adapter = AndroidMock.createMock(TransitAdapter.class);

        AndroidMock.expect(adapter.evaluate(contains("__TRANSIT_JS_FUNCTION_1(1)"))).andReturn(11);
        AndroidMock.expect(adapter.evaluate(contains("__TRANSIT_JS_FUNCTION_1(2, 0, 0)"))).andReturn(12);
        AndroidMock.expect(adapter.evaluate(contains("__TRANSIT_JS_FUNCTION_1.call(0, 3)"))).andReturn(13);
        AndroidMock.expect(adapter.evaluate("transit.r(\"1\")()")).andReturn(14);
        AndroidMock.replay(adapter);

        AndroidTransitContext ctx = new AndroidTransitContext(adapter);
        TransitJSFunction f = new TransitJSFunction(ctx, "1");
        Object f1 = f.call(1);
        Object f2 = f.callWithThisArg(ctx, 2, 0, 0);
        Object f3 = f.callWithThisArg(0, 3);
        Object f4 = f.call();

        AndroidMock.verify(adapter);
        assertEquals(11, f1);
        assertEquals(12, f2);
        assertEquals(13, f3);
        assertEquals(14, f4);
    }

}

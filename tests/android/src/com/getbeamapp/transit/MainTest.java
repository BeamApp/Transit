package com.getbeamapp.transit;

import junit.framework.TestCase;
import android.os.ConditionVariable;

public class MainTest extends TestCase {

    private final TransitCallable noop;

    public MainTest() {
        this.noop = new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                return null;
            }
        };
    }

    public void testExpressionsFromCode() {
        assertEquals("no arguments", TransitProxy.jsExpressionFromCode("no arguments"));
        assertEquals("int: 23", TransitProxy.jsExpressionFromCode("int: @", 23));
        assertEquals("float: 42.5", TransitProxy.jsExpressionFromCode("float: @", 42.5));
        assertEquals("bool: true", TransitProxy.jsExpressionFromCode("bool: @", true));
        assertEquals("bool: false", TransitProxy.jsExpressionFromCode("bool: @", false));
        assertEquals("string: \"foobar\"", TransitProxy.jsExpressionFromCode("string: @", "foobar"));
        assertEquals("\"foo\" + \"bar\"", TransitProxy.jsExpressionFromCode("@ + @", "foo", "bar"));
        assertEquals("'baz' + \"bam\" + 23", TransitProxy.jsExpressionFromCode("'baz' + @ + @", "bam", 23));
    }

    public void testWrongArgumentCount() {
        assertEquals("arg: @", TransitProxy.jsExpressionFromCode("arg: @"));
        assertEquals("arg: 1", TransitProxy.jsExpressionFromCode("arg: @", 1, 2));
    }

    public void testCustomRepresentation() {
        JavaScriptRepresentable object = new JavaScriptRepresentable() {

            @Override
            public String getJavaScriptRepresentation() {
                return "myRepresentation";
            }
        };

        assertEquals("return myRepresentation", TransitProxy.jsExpressionFromCode("return @", object));
    }

    public void testInvalidObject() {
        try {
            TransitProxy.jsExpressionFromCode("@", this);
            fail();
        } catch (IllegalArgumentException e) {
            // ok
        }
    }

    public void testFunction() {
        TransitNativeFunction function = new TransitNativeFunction(null, noop, "some-id");
        assertEquals("transit.nativeFunction(\"some-id\")", function.getJavaScriptRepresentation());
    }

    public void testFunctionInExpression() {
        TransitNativeFunction function = new TransitNativeFunction(null, noop, "some-id");
        assertEquals("transit.nativeFunction(\"some-id\")('foo')", TransitProxy.jsExpressionFromCode("@('foo')", function));
    }

    public void testFunctionDisposal() {
        final ConditionVariable lock = new ConditionVariable();

        @SuppressWarnings("unused")
        TransitNativeFunction function = new TransitNativeFunction(null, noop, "some-id") {
            @Override
            protected void finalize() throws Throwable {
                super.finalize();
                lock.open();
            }
        };

        function = null;
        System.gc();
        assertTrue("Function not garbage collected.", lock.block(1000));
    }

}

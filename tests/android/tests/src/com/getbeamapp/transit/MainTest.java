package com.getbeamapp.transit;

import static com.getbeamapp.transit.TestHelpers.assertContains;

import java.util.EnumSet;

import junit.framework.TestCase;
import android.os.ConditionVariable;

import com.getbeamapp.transit.TransitCallable.Flags;

public class MainTest extends TestCase {

    private final TransitCallable noop;
    private TransitContext transit;

    public MainTest() {
        this.noop = new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                return null;
            }
        };
        
        this.transit = new TransitContext() {
            
            @Override
            public Object evalWithThisArg(String arg0, Object arg1, Object... arg2) {
                return null;
            }
            
            @Override
            public void evalWithThisArgAsync(String arg0, Object arg1, Object... arg2) {
                
            }
            
            @Override
            public void releaseProxy(String arg0) {
                return;
            }
        };
    }

    public void testExpressionsFromCode() {
        assertEquals("no arguments", transit.jsExpressionFromCode("no arguments"));
        assertEquals("int: 23", transit.jsExpressionFromCode("int: @", 23));
        assertEquals("float: 42.5", transit.jsExpressionFromCode("float: @", 42.5));
        assertEquals("bool: true", transit.jsExpressionFromCode("bool: @", true));
        assertEquals("bool: false", transit.jsExpressionFromCode("bool: @", false));
        assertEquals("string: \"foobar\"", transit.jsExpressionFromCode("string: @", "foobar"));
        assertEquals("\"foo\" + \"bar\"", transit.jsExpressionFromCode("@ + @", "foo", "bar"));
        assertEquals("'baz' + \"bam\" + 23", transit.jsExpressionFromCode("'baz' + @ + @", "bam", 23));
        assertEquals("(function() { return this; }).call(2)", TestHelpers.reduceWhitespace(transit.jsExpressionFromCodeWithThis("this", 2)));
    }

    public void testWrongArgumentCount() {
        assertEquals("arg: 1", transit.jsExpressionFromCode("arg: @", 1, 2));
        
        try {
            transit.jsExpressionFromCode("arg: @");
            fail();
        } catch (IllegalArgumentException e) {
            // ok
        }
    }
    
    public void testExrepssionFromProxy() {
        TransitNativeFunction f = transit.registerCallable(noop);
        assertEquals("(function() { var __TRANSIT_NATIVE_FUNCTION_0 = transit.nativeFunction(\"0\"); return setTimeout(__TRANSIT_NATIVE_FUNCTION_0, 1000); })()", TestHelpers.reduceWhitespace(transit.jsExpressionFromCode("setTimeout(@, 1000)", f)));
    }
    
    public void testNativeFunctionOptions() {
        TransitNativeFunction fNoThis = transit.registerCallable(noop, EnumSet.of(Flags.NO_THIS));
        assertContains("transit.nativeFunction(\"0\", {\"noThis\": true})", transit.jsExpressionFromCode("@", fNoThis));
        
        TransitNativeFunction fAsync = transit.registerCallable(noop, EnumSet.of(Flags.ASYNC));
        assertContains("transit.nativeFunction(\"1\", {\"async\": true})", transit.jsExpressionFromCode("@", fAsync));
        
        TransitNativeFunction fDefault = transit.registerCallable(noop);
        assertContains("transit.nativeFunction(\"2\")", transit.jsExpressionFromCode("@", fDefault));
    }

    public void testCustomRepresentation() {
        JSRepresentable object = new JSRepresentable() {

            @Override
            public String getJSRepresentation() {
                return "myRepresentation";
            }
        };

        assertEquals("return myRepresentation", transit.jsExpressionFromCode("return @", object));
    }

    public void testInvalidObject() {
        try {
            transit.jsExpressionFromCode("@", this);
            fail();
        } catch (IllegalArgumentException e) {
            // ok
        }
    }
    
    public void testProxify() {
        assertEquals(Integer.class, transit.parse("1").getClass());
        assertEquals(String.class, transit.parse("\"a\"").getClass());
        assertEquals(TransitJSFunction.class, transit.parse("\"__TRANSIT_JS_FUNCTION_1000\"").getClass());
        
        try {
            transit.parse("\"__TRANSIT_NATIVE_FUNCTION_1000\"");
            fail();
        } catch (IllegalArgumentException e) {
            // ok
        }
    }

    public void testFunctionDisposal() {
        final ConditionVariable lock = new ConditionVariable();

        @SuppressWarnings("unused")
        TransitNativeFunction function = new TransitNativeFunction(null, noop, EnumSet.noneOf(Flags.class), "some-id") {
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

package com.getbeamapp.transit.common;

import static com.getbeamapp.transit.common.TestHelpers.assertContains;

import java.util.EnumSet;

import junit.framework.TestCase;
import android.os.ConditionVariable;

import com.getbeamapp.transit.common.TransitCallable.Flags;

public class MainTest extends TestCase {

    private TransitContext transit;
   
    @Override
    protected void setUp() throws Exception {
        this.transit = TestHelpers.createNoopContext();
    }

    public void testFormattingWithNoValues() {
        assertEquals("no values", transit.jsExpressionFromCode("no values"));
    }
    
    public void testFormattingWithNativeValues() {
        assertEquals("int: 23", transit.jsExpressionFromCode("int: @", 23));
        assertEquals("float: 42.5", transit.jsExpressionFromCode("float: @", 42.5));
        assertEquals("bool: true", transit.jsExpressionFromCode("bool: @", true));
        assertEquals("bool: false", transit.jsExpressionFromCode("bool: @", false));
        assertEquals("string: \"foobar\"", transit.jsExpressionFromCode("string: @", "foobar"));
        assertEquals("\"foo\" + \"bar\"", transit.jsExpressionFromCode("@ + @", "foo", "bar"));
        assertEquals("'baz' + \"bam\" + 23", transit.jsExpressionFromCode("'baz' + @ + @", "bam", 23));
    }
    
    public void testFormattingWithCustomRepresentation() {
        JSRepresentable object = new JSRepresentable() {
            @Override
            public String getJSRepresentation() {
                return "myRepresentation";
            }
        };

        assertEquals("return myRepresentation", transit.jsExpressionFromCode("return @", object));
    }

    public void testFormattingWithInvalidObject() {
        Object invalidObject = this; // this = instance of MainTest
        
        try {
            transit.jsExpressionFromCode("@", invalidObject);
            fail();
        } catch (IllegalArgumentException e) {
            // ok
        }
    }
    
    public void testFormattingWithThisArg() {
        assertEquals("(function() { return this; }).call(2)", TestHelpers.reduceWhitespace(transit.jsExpressionFromCodeWithThis("this", 2)));
    }

    public void testFormattingWithTooManyValues() {
        assertEquals("arg: 1", transit.jsExpressionFromCode("arg: @", 1, 2));
    }
    
    public void testFormattingWithTooFewValues() {
        try {
            transit.jsExpressionFromCode("arg: @");
            fail();
        } catch (IllegalArgumentException e) {
            // ok
        }
    }
    
    public void testFormattingOfProxyWithVars() {
        TransitNativeFunction f = transit.registerCallable(TransitCallable.NOOP);
        String expression = TestHelpers.reduceWhitespace(transit.jsExpressionFromCode("setTimeout(@, 1000)", f));
        assertEquals("(function() { var __TRANSIT_NATIVE_FUNCTION_0 = transit.nativeFunction(\"0\"); return setTimeout(__TRANSIT_NATIVE_FUNCTION_0, 1000); })()", expression);
    }
    
    public void testFormattingWithNativeFunction() {
        TransitNativeFunction fDefault = transit.registerCallable(TransitCallable.NOOP);
        assertContains("transit.nativeFunction(\"0\")", transit.jsExpressionFromCode("@", fDefault));
    }
    
    public void testFormattingWithNativeFunctionWithoutThis() {
        TransitNativeFunction fNoThis = transit.registerCallable(TransitCallable.NOOP, EnumSet.of(Flags.NO_THIS));
        assertContains("transit.nativeFunction(\"0\", {\"noThis\": true})", transit.jsExpressionFromCode("@", fNoThis));
    }
    
    public void testFormattingWithAsyncNativeFunction() {
        TransitNativeFunction fAsync = transit.registerCallable(TransitCallable.NOOP, EnumSet.of(Flags.ASYNC));
        assertContains("transit.nativeFunction(\"0\", {\"async\": true})", transit.jsExpressionFromCode("@", fAsync));        
    }
    
    public void testFormattingWithAsyncNativeFunctionWithoutThis() {
        TransitNativeFunction fAsyncNoThis = transit.registerCallable(TransitCallable.NOOP, EnumSet.of(Flags.ASYNC, Flags.NO_THIS));
        assertContains("transit.nativeFunction(\"0\", {\"async\": true, \"noThis\": true})", transit.jsExpressionFromCode("@", fAsyncNoThis));        
    }
    
    public void testParsingOfNativeTypes() {
        assertEquals(null, transit.parse("null"));
        assertEquals(Integer.class, transit.parse("1").getClass());
        assertEquals(Float.class, transit.parse("1.5").getClass());
        assertEquals(String.class, transit.parse("\"a\"").getClass());
        assertEquals(Boolean.class, transit.parse("true").getClass());
        assertEquals(Boolean.class, transit.parse("false").getClass());
    }
    
    public void testParsingOfGlobalObject() {
        Object object = transit.parse("\"__TRANSIT_OBJECT_GLOBAL\"");
        assertTrue(TransitContext.class.isAssignableFrom(object.getClass()));
        assertEquals(transit, object);
    }
    
    public void testParsingOfTransitObjectProxies() {
        Object transitProxy = transit.parse("\"__TRANSIT_OBJECT_PROXY_1000\"");
        assertEquals(TransitProxy.class, transitProxy.getClass());
        assertEquals("__TRANSIT_OBJECT_PROXY_1000", ((TransitProxy) transitProxy).getProxyId());
    }
    
    public void testParsingOfTransitJsFunctions() {
        Object transitJsFunction = transit.parse("\"__TRANSIT_JS_FUNCTION_1000\"");
        assertEquals(TransitJSFunction.class, transitJsFunction.getClass());
        assertEquals("__TRANSIT_JS_FUNCTION_1000", ((TransitJSFunction) transitJsFunction).getProxyId());
    }
    
    public void testParsingOfTransitNativeFunctions() {
        TransitNativeFunction function = transit.registerCallable(TransitCallable.NOOP);
        assertEquals("0", function.getNativeId());
        
        Object transitNativeFunction = transit.parse("\"__TRANSIT_NATIVE_FUNCTION_" + function.getNativeId() + "\"");
        assertEquals(TransitNativeFunction.class, transitNativeFunction.getClass());
        
        assertEquals(function, transitNativeFunction);
    }
    
    public void testParsingOfNonExistingNativeFunctions() {
        try {
            transit.parse("\"__TRANSIT_NATIVE_FUNCTION_DOES_NOT_EXIST\"");
            fail();
        } catch (IllegalArgumentException e) {
            // ok
        }
    }

    public void testFunctionDisposal() {
        final ConditionVariable lock = new ConditionVariable();

        @SuppressWarnings("unused")
        TransitNativeFunction function = new TransitNativeFunction(null, TransitCallable.NOOP, EnumSet.noneOf(Flags.class), "some-id") {
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

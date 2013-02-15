package com.getbeamapp.transit;

import java.util.List;
import java.util.Map;

import junit.framework.TestCase;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.os.ConditionVariable;

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
            public TransitProxy evalWithThisArg(String arg0, Object arg1, Object... arg2) {
                return null;
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
        assertEquals("arg: @", transit.jsExpressionFromCode("arg: @"));
        assertEquals("arg: 1", transit.jsExpressionFromCode("arg: @", 1, 2));
    }
    
    public void testExrepssionFromProxy() {
        TransitNativeFunction f = transit.registerCallable(noop);
        assertEquals("(function() { var __TRANSIT_NATIVE_FUNCTION_0 = transit.nativeFunction(\"0\"); return setTimeout(__TRANSIT_NATIVE_FUNCTION_0, 1000); })()", TestHelpers.reduceWhitespace(transit.jsExpressionFromCode("setTimeout(@, 1000)", f)));
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
        assertEquals(Integer.class, transit.proxify(1).getClass());
        assertEquals(String.class, transit.proxify("a").getClass());
        assertEquals(TransitJSFunction.class, transit.proxify("__TRANSIT_JS_FUNCTION_1000").getClass());
        assertNull(transit.proxify("__TRANSIT_NATIVE_FUNCTION_1000"));
    }
    
    @SuppressWarnings("unchecked")
    public void testJsonParsing() throws JSONException {
        JSONObject o = new JSONObject();
        o.put("null", null);
        o.put("a", 1);
        
        JSONObject o2 = new JSONObject();
        o2.put("c", "2");
        o.put("b", o2);
        
        JSONArray a = new JSONArray();
        a.put(3);
        a.put("4");
        o.put("d", a);
        
        Map<String, Object> map = JsonConverter.toNativeMap(o);
        assertNull(map.get("null"));
        assertEquals(1, map.get("a"));
        assertEquals("2", ((Map<String, Object>) map.get("b")).get("c"));
        assertEquals(3, ((List<Object>) map.get("d")).get(0));
        assertEquals("4", ((List<Object>) map.get("d")).get(1));
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

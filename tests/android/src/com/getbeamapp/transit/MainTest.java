package com.getbeamapp.transit;

import java.util.List;
import java.util.Map;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.getbeamapp.transit.prompt.TransitChromeClient;

import junit.framework.TestCase;
import android.os.ConditionVariable;

public class MainTest extends TestCase {

    private final TransitCallable noop;

    public MainTest() {
        this.noop = new TransitCallable() {
            @Override
            public Object evaluate(TransitProxy thisArg, TransitProxy... arguments) {
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

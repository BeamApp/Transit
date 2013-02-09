package com.getbeamapp.transit;

import java.util.concurrent.Semaphore;

import android.app.NativeActivity;
import android.os.ConditionVariable;
import android.test.ActivityInstrumentationTestCase2;
import android.util.Log;

import com.getbeamapp.transit.MainActivity;
import com.getbeamapp.transit.TransitNativeFunction;
import com.getbeamapp.transit.TransitProxy;

public class AndroidTest extends ActivityInstrumentationTestCase2<MainActivity> {

	public AndroidTest() {
		super(MainActivity.class);
	}

	public void testPresence() {
		assertNotNull(getActivity());
	}

	public void testAdd() {
		assertEquals(4, getActivity().transit.eval("2 + 2"));
	}

	public void testExpressionsFromCode() {
		assertEquals("no arguments",
				TransitProxy.jsExpressionFromCode("no arguments"));
		assertEquals("int: 23", TransitProxy.jsExpressionFromCode("int: @", 23));
		assertEquals("float: 42.5",
				TransitProxy.jsExpressionFromCode("float: @", 42.5));
		assertEquals("bool: true",
				TransitProxy.jsExpressionFromCode("bool: @", true));
		assertEquals("bool: false",
				TransitProxy.jsExpressionFromCode("bool: @", false));
		assertEquals("string: \"foobar\"",
				TransitProxy.jsExpressionFromCode("string: @", "foobar"));
		assertEquals("\"foo\" + \"bar\"",
				TransitProxy.jsExpressionFromCode("@ + @", "foo", "bar"));
		assertEquals("'baz' + \"bam\" + 23",
				TransitProxy.jsExpressionFromCode("'baz' + @ + @", "bam", 23));
	}

	public void testWrongArgumentCount() {
		assertEquals("arg: @", TransitProxy.jsExpressionFromCode("arg: @"));
		assertEquals("arg: 1",
				TransitProxy.jsExpressionFromCode("arg: @", 1, 2));
	}

	public void testCustomRepresentation() {
		JavaScriptRepresentable object = new JavaScriptRepresentable() {

			@Override
			public String getJavaScriptRepresentation() {
				return "myRepresentation";
			}
		};

		assertEquals("return myRepresentation",
				TransitProxy.jsExpressionFromCode("return @", object));
	}
	
	public void testInvalidObject() {
		try {
			TransitProxy.jsExpressionFromCode("@", this);
			fail();
		} catch (IllegalArgumentException e) {
			assertTrue(true);
		}
	}

	public void testFunction() {
		TransitNativeFunction function = new TransitNativeFunction(null,
				"some-id");

		assertEquals("transit.nativeFunction(\"some-id\")",
				function.getJavaScriptRepresentation());
	}

	public void testFunctionInExpression() {
		TransitNativeFunction function = new TransitNativeFunction(null,
				"some-id");
		assertEquals("transit.nativeFunction(\"some-id\")('foo')",
				TransitProxy.jsExpressionFromCode("@('foo')", function));
	}
	
	public void testFunctionDisposal() {
		final ConditionVariable lock = new ConditionVariable();
		
		@SuppressWarnings("unused")
		TransitNativeFunction function = new TransitNativeFunction(null,
				"some-id") {
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

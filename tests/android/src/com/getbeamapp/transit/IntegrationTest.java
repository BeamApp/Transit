package com.getbeamapp.transit;

import java.util.Arrays;
import java.util.EnumSet;
import java.util.LinkedList;
import java.util.List;

import android.test.ActivityInstrumentationTestCase2;
import android.util.Log;

import com.getbeamapp.transit.TransitCallable.Flags;
import com.getbeamapp.transit.prompt.TransitPromptAdapter;

public class IntegrationTest extends ActivityInstrumentationTestCase2<MainActivity> {

    public final long TIMEOUT = 1000L;
    public final long BENCHMARK_TIMES = 100L;

    public IntegrationTest() {
        super(MainActivity.class);
    }

    public void testAllSetup() {
        MainActivity activity = getActivity();
        assertNotNull(activity);

        AndroidTransitContext transit = activity.transit;
        assertNotNull(transit);
        assertNotNull(transit.getAdapter());

        TransitPromptAdapter adapter = (TransitPromptAdapter) transit.getAdapter();
        assertNotNull(adapter.getScript());
    }

    public void testTransitInjected() {
        assertEquals(true, (boolean) (Boolean) getActivity().transit.eval("window.transit != null"));
    }

    public void testAsyncInvocation() {
        TransitContext transit = getActivity().transit;
        MockCallable callable = new MockCallable();
        TransitNativeFunction f = transit.registerCallable(callable, EnumSet.of(Flags.ASYNC));
        transit.eval("@()", f);
        assertEquals(0, callable.getCallCount()); // setTimeout for
                                                  // batch-processing won't have
                                                  // fired yet
        callable.block();
        assertEquals(1, callable.getCallCount());
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
        assertEquals(4, getActivity().transit.eval("2 + 2"));
    }

    public void testContext() {
        AndroidTransitContext transit = getActivity().transit;
        assertEquals(1, transit.evalWithThisArg("this", 1));
        assertEquals(transit, transit.eval("this"));
    }

    public void testNativeFunction() {
        final boolean[] called = new boolean[] { false };

        AndroidTransitContext transit = getActivity().transit;
        TransitCallable callable = new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                called[0] = true;
                return 42;
            }
        };

        TransitNativeFunction function = transit.registerCallable(callable);
        Object result = transit.eval("@()", function);

        assertTrue("Native function not called.", called[0]);
        assertEquals(42, result);
    }

    public void testNativeArguments() {
        final Object[] calledWithThis = new Object[] { null };
        final List<Object> calledWithArgs = new LinkedList<Object>();

        AndroidTransitContext transit = getActivity().transit;
        TransitCallable callable = new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                calledWithThis[0] = thisArg;
                calledWithArgs.addAll(Arrays.asList(arguments));
                return null;
            }
        };

        TransitNativeFunction function = transit.registerCallable(callable);
        transit.eval("@.call(0, 1, 2)", function);

        assertNotNull(calledWithThis[0]);
        assertEquals(2, calledWithArgs.size());

        assertEquals(0, calledWithThis[0]);
        assertEquals(1, calledWithArgs.get(0));
        assertEquals(2, calledWithArgs.get(1));
    }

    public void testNativeIdentity() {
        final List<Object> calledWithArgs = new LinkedList<Object>();

        AndroidTransitContext transit = getActivity().transit;

        TransitNativeFunction function = transit.registerCallable(new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                calledWithArgs.addAll(Arrays.asList(arguments));
                return null;
            }
        });

        transit.eval("@(@, @)", function, function, function);

        assertEquals(2, calledWithArgs.size());
        assertEquals(function, calledWithArgs.get(0));
        assertEquals(calledWithArgs.get(0), calledWithArgs.get(1));
    }

    public void testNativeRecursion() {
        final int calls = 100; // Change to higher value if needed (1000 calls
                               // require ~8s on my machine)

        final AndroidTransitContext transit = getActivity().transit;
        final TransitCallable callable = new TransitCallable() {
            @Override
            public Object evaluate(Object thisArg, Object... arguments) {
                int v = (Integer) arguments[0];

                if (v < calls) {
                    return transit.eval(transit.jsExpressionFromCode("f(@ + 1)", v));
                } else {
                    return v;
                }
            }
        };

        final TransitNativeFunction function = transit.registerCallable(callable);
        transit.eval("window.f = @", function);
        assertEquals(calls, transit.eval("f(0)"));
    }

    public void testNativeToJsBenchmarkSync() {
        final AndroidTransitContext transit = getActivity().transit;
        MockCallable callable = new MockCallable();

        transit.eval("window.c = @", transit.registerCallable(callable, EnumSet.allOf(TransitCallable.Flags.class)));
        transit.eval("window.i = 0");
        transit.eval("window.f = function() { window.i++; if(window.i == @) { window.c() } } ", BENCHMARK_TIMES);

        long start = System.nanoTime();

        for (int i = 0; i < BENCHMARK_TIMES; i++) {
            transit.eval("window.f()");
        }

        callable.block();

        long end = System.nanoTime();
        Log.d("BENCHMARK", String.format("%d sequential calls needed %d", BENCHMARK_TIMES, (end - start) / 1000000));
    }

    public void testNativeToJsBenchmarkAsync() {
        final AndroidTransitContext transit = getActivity().transit;
        MockCallable callable = new MockCallable();

        transit.eval("window.c = @", transit.registerCallable(callable, EnumSet.allOf(TransitCallable.Flags.class)));
        transit.eval("window.i = 0");
        transit.eval("window.f = function() { window.i++; if(window.i == @) { window.c() } } ", BENCHMARK_TIMES);

        long start = System.nanoTime();

        for (int i = 0; i < BENCHMARK_TIMES; i++) {
            transit.evalAsync("window.f()");
        }

        callable.block();

        long end = System.nanoTime();
        Log.d("BENCHMARK", String.format("%d async calls needed %d", BENCHMARK_TIMES, (end - start) / 1000000));
    }
}

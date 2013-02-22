package com.getbeamapp.transit.common;

import junit.framework.TestCase;

public final class TestHelpers {
    public static String reduceWhitespace(String input) {
        return input.trim().replaceAll("[\\r\\n\\s\\t]+", " ");
    }

    public static void assertContains(Object contained, String containingString) {
        TestCase.assertNotNull(contained);
        TestCase.assertNotNull(containingString);

        String otherString = String.valueOf(contained);

        if (!containingString.contains(otherString)) {
            TestCase.fail(String.format("Expected `%s` to contain `%s`", containingString, otherString));
        }
    }
    
    public static TransitContext createNoopContext() {
        return new TransitContext() {
            
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
}

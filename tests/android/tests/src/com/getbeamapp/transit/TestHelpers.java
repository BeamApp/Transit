package com.getbeamapp.transit;

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
}

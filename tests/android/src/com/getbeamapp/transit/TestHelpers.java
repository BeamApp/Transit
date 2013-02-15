package com.getbeamapp.transit;

public final class TestHelpers {
    public static String reduceWhitespace(String input) {
        return input.trim().replaceAll("[\\r\\n\\s\\t]+", " ");
    }
}

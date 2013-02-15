package com.getbeamapp.transit;

import org.easymock.IArgumentMatcher;

import com.google.android.testing.mocking.AndroidMock;

public class Matchers {
    public static String contains(final String s) {
        AndroidMock.reportMatcher(new IArgumentMatcher() {

            @Override
            public boolean matches(Object input) {
                return (input instanceof String) && ((String) input).contains(s);
            }

            @Override
            public void appendTo(StringBuffer buffer) {
                buffer.append("contains(");
                buffer.append(s);
                buffer.append(")");
            }
        });

        return null;
    }
}

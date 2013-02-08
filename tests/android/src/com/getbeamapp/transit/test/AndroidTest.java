package com.getbeamapp.transit.test;

import android.test.ActivityInstrumentationTestCase2;

import com.getbeamapp.transit.MainActivity;

import junit.framework.TestCase;

public class AndroidTest extends ActivityInstrumentationTestCase2<MainActivity> {

	public AndroidTest() {
		super(MainActivity.class);
	}

	public void testPresence() {
		assertNotNull(getActivity());
	}
	
	public void testAdd() {
		assertEquals(4, getActivity().transit.evaluate("2 + 2"));
	}

}

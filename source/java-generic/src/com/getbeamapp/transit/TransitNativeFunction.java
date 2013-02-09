package com.getbeamapp.transit;

public class TransitNativeFunction extends TransitFunction implements JavaScriptRepresentable {

	private final String nativeId;
	
	public TransitNativeFunction(AbstractTransitContext rootContext) {
		super(rootContext);
		this.nativeId = rootContext.nextNativeId();
		assert(nativeId != null);
	}
	
	TransitNativeFunction(AbstractTransitContext rootContext, String nativeId) {
		super(rootContext);
		this.nativeId = nativeId;
		assert(nativeId != null);
	}

	@Override
	public TransitProxy call(TransitProxy context, Object... arguments) {
		return null;
	}
	
	@Override
	public String getJavaScriptRepresentation() {
		return "transit.nativeFunction(\"" + nativeId + "\")";
	}

}

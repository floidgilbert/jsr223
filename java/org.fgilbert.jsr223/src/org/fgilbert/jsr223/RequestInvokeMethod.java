package org.fgilbert.jsr223;

class RequestInvokeMethod {

	private Object[] arguments;
	private String methodName;
	private String objectName;
	
	public RequestInvokeMethod(String objectName, String methodName, Object... arguments) {
		this.arguments = arguments;
		this.methodName = methodName;
		this.objectName = objectName;
	}
	
	public Object[] getArguments() {
		return this.arguments;
	}

	public String getMethodName() {
		return this.methodName;
	}

	public String getObjectName() {
		return this.objectName;
	}

}

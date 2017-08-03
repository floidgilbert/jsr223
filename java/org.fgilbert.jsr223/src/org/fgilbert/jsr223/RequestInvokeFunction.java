package org.fgilbert.jsr223;

class RequestInvokeFunction {

	private Object[] arguments;
	private String functionName;
	
	public RequestInvokeFunction(String functionName, Object... arguments) {
		this.arguments = arguments;
		this.functionName = functionName;
	}
	
	public Object[] getArguments() {
		return this.arguments;
	}

	public String getFunctionName() {
		return this.functionName;
	}

}

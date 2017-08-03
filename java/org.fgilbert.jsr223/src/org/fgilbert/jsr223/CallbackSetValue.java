package org.fgilbert.jsr223;

import org.fgilbert.jdx.JavaToR;

class CallbackSetValue {

	private String key;
	private JavaToR value;
	
	public CallbackSetValue(String key, JavaToR value) {
		this.key = key;
		this.value = value;
	}

	String getKey() {
		return key;
	}

	void setKey(String key) {
		this.key = key;
	}
	
	JavaToR getValue() {
		return value;
	}

	void setValue(JavaToR value) {
		this.value = value;
	}

}

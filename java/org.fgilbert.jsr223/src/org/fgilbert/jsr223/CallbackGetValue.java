package org.fgilbert.jsr223;

class CallbackGetValue {

	private String key;
	
	CallbackGetValue(String key) {
		this.key = key;
	}

	String getKey() {
		return key;
	}

	void setKey(String key) {
		this.key = key;
	}

	@Override
	public String toString() {
		return key;
	}

}

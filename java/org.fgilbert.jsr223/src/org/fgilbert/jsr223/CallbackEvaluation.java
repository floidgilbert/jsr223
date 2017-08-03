package org.fgilbert.jsr223;

class CallbackEvaluation {

	private String script;
	
	CallbackEvaluation(String script) {
		this.script = script;
	}

	String getScript() {
		return script;
	}

	void setScript(String script) {
		this.script = script;
	}
	
	@Override
	public String toString() {
		return script;
	}

}

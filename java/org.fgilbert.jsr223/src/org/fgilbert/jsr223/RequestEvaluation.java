package org.fgilbert.jsr223;

import javax.script.Bindings;
import javax.script.CompiledScript;

class RequestEvaluation {

	private Bindings bindings;
	private CompiledScript compiledScript;
	private boolean discardReturnValue;
	private String script;
	
	RequestEvaluation(String script, boolean discardReturnValue, Bindings bindings) {
		this.script = script;
		this.discardReturnValue = discardReturnValue;
		this.bindings = bindings;
	}

	RequestEvaluation(CompiledScript compiledScript, boolean discardReturnValue, Bindings bindings) {
		this.compiledScript = compiledScript;
		this.discardReturnValue = discardReturnValue;
		this.bindings = bindings;
	}

	Bindings getBindings() {
		return bindings;
	}

	CompiledScript getCompiledScript() {
		return compiledScript;
	}

	boolean getDiscardReturnValue() {
		return discardReturnValue;
	}

	String getScript() {
		return script;
	}

}

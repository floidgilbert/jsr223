/*
 * This project was written to optimize marshalling data and messages between the JVM and R via rJava. 
 * A balance between performance and code clarity is the goal, but intuition has been sacrificed 
 * in many cases for the sake of speed. All code is designed to reduce the number of calls from R by rJava.   
 */

package org.fgilbert.jsr223;

import java.io.StringWriter;
import java.io.Writer;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import java.util.concurrent.ArrayBlockingQueue;

import javax.script.*;

import org.fgilbert.jdx.JavaToR;
import org.fgilbert.jdx.JavaToR.ArrayOrder;
import org.fgilbert.jsr223.Message.MessageType;
import org.fgilbert.jsr223.Message.Subject;

public class Controller {
	
	public enum StandardOutputMode {
		CONSOLE, QUIET, BUFFER;
	}
	
	public static final int CALLBACK_EVALUATION = 0x01000000;
	public static final int CALLBACK_GET_VALUE = 0x02000000;
	public static final int CALLBACK_SET_VALUE = 0x03000000;
	
	private final int STANDARD_OUTPUT_BUFFER_SIZE_DEFAULT = 4096;
	private final int STANDARD_OUTPUT_BUFFER_SIZE_MAX = 4096000;  // If buffer exceeds this size, shrink to this size.

	private JavaToR.ArrayOrder arrayOrder = ArrayOrder.ROW_MAJOR;
	private Writer defaultContextWriter;
	private ScriptEngine engine;
	private String[][] engineInformation;
	private EvaluationThread evaluationThread;
	private boolean initialized;
	private ScriptEngineManager manager = new ScriptEngineManager();
	private ArrayBlockingQueue<JavaToR> queue = new ArrayBlockingQueue<JavaToR>(1);
	private RClient rClient;
	private JavaToR response = new JavaToR();
	private StandardOutputMode standardOutputMode = StandardOutputMode.CONSOLE;

	public Controller(String engineShortName) throws Exception {
		engine = manager.getEngineByName(engineShortName);
		if (engine == null)
			throw new Exception(String.format(
					"Failed to instantiate engine '%s'. Make sure the engine dependencies are in the class path.",
					engineShortName));
		ScriptEngineFactory factory = engine.getFactory();
		engineInformation = new String[][] {
				{
					"name"
					, "short.names"
					, "version"
					, "language.name"
					, "language.version"
					, "extensions"
					, "mime.types"
				}
				, {
					factory.getEngineName()
					, factory.getNames().toString()
					, factory.getEngineVersion()
					, factory.getLanguageName()
					, factory.getLanguageVersion()
					, factory.getExtensions().toString()
					, factory.getMimeTypes().toString()
				}
		};
		evaluationThread = new EvaluationThread(this, engine);
		evaluationThread.start();
		rClient = new RClient(this, evaluationThread);
		engine.put("R", rClient);
		initialized = true;
	}
	
	public void clearStandardOutput() {
		if (!initialized)
			throw new IllegalStateException();
		try {
			StringWriter sw = (StringWriter) engine.getContext().getWriter();
			StringBuffer sb = sw.getBuffer();
			if (sb.length() > STANDARD_OUTPUT_BUFFER_SIZE_MAX) {
				sb.setLength(STANDARD_OUTPUT_BUFFER_SIZE_MAX);
				// ensureCapacity does not shrink the buffer if a smaller value is given.
				// Therefore, trimToSize must be called first.
				sb.trimToSize();
				sb.ensureCapacity(STANDARD_OUTPUT_BUFFER_SIZE_MAX);
			}
			// Reset the buffer.
			sb.setLength(0);
		} catch(Throwable e) {
			// Do nothing.
		}
	}
	
	public CompiledScript compileScript(String script) throws ScriptException {
		if (!initialized)
			throw new IllegalStateException();
		javax.script.Compilable comp = (javax.script.Compilable) engine;
		return(comp.compile(script));
	}
	
	public ArrayOrder getArrayOrder() {
		return this.arrayOrder;
	}

	public int getBindings() {
		if (!initialized)
			throw new IllegalStateException();
		Map<String, Object> m = engine.getBindings(ScriptContext.ENGINE_SCOPE);
		// Using TreeMap to order the members by the key.
		TreeMap<String, String> tm = new TreeMap<String, String>(
				(Comparator<? super String>) (String a, String b) -> {
					int n = a.compareToIgnoreCase(b);
					if (n != 0)
						return n;
					return a.compareTo(b);
				}
		);
		Object value = null;
		for (Map.Entry<String, Object> me : m.entrySet()) {
			value = me.getValue();
			if (value == null) {
				tm.put(me.getKey(), "null");
			} else {
				tm.put(me.getKey(), value.getClass().getName());
			}
		}
		return response.initialize(tm, this.arrayOrder);
	}

	public String[][] getEngineInformation() {
		if (!initialized)
			throw new IllegalStateException();
		return engineInformation;
	}
	
	public JavaToR getResponse() {
		return response;
	}
	
	public String[] getResponseCallbackSetValue() {
		CallbackSetValue cpv = (CallbackSetValue) response.getValueObject();
		return new String[] {cpv.getKey(), Integer.toString(response.initializeFrom(cpv.getValue()))};
	}

	public int getScriptEngineValue(String key) {
		if (!initialized)
			throw new IllegalStateException();
		// Read the comment in 'waitForEvaluation'.
		return response.initialize(engine.get(key), this.arrayOrder);
	}

	public String getScriptEngineValueClassName(String key) {
		if (!initialized)
			throw new IllegalStateException();
		Object o = engine.get(key);
		return (o == null) ? null : o.getClass().getName();
	}
	
	public StandardOutputMode getStandardOutputMode() {
		return standardOutputMode;
	}

	public boolean isInitialized() {
		return this.initialized;
	}
	
	public String getStandardOutput() {
		if (!initialized)
			throw new IllegalStateException();
		try {
			StringWriter sw = (StringWriter) engine.getContext().getWriter();
			String result = sw.toString();
			this.clearStandardOutput();
			return result;
		} catch(Throwable e) {
			return null;
		}
	}
	
	public void putCallbackResponse(boolean value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(boolean[] value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(boolean[][] value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(byte value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(byte[] value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(byte[][] value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(double value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(double[] value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(double[][] value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(int value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(int[] value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(int[][] value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}

	public void putCallbackResponse(List<?> value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}
	
	public void putCallbackResponse(Map<?, ?> value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}
	
	public void putCallbackResponse(Object value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}
	
	public void putCallbackResponse(String value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}
	
	public void putCallbackResponse(String[] value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}
	
	public void putCallbackResponse(String[][] value) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_OK, value));
	}
	
	public void putCallbackResponseError(String errorMessage) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(new Message(MessageType.RESPONSE, Subject.RSP_ERROR, errorMessage));
	}

	public void putEvaluationRequest(CompiledScript compiledScript, boolean discardReturnValue) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(
			new Message(
				MessageType.REQUEST
				, Subject.RQ_EVALUATE
				, new RequestEvaluation(compiledScript, discardReturnValue, null)
			)
		);
	}

	public void putEvaluationRequest(CompiledScript compiledScript, boolean discardReturnValue, Map<String, Object> bindings) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		SimpleBindings sb = null;
		if (bindings != null) {
			sb = new SimpleBindings(bindings);
			sb.put("R", this.rClient);
		}
		evaluationThread.putQueueItem(
			new Message(
				MessageType.REQUEST
				, Subject.RQ_EVALUATE
				, new RequestEvaluation(compiledScript, discardReturnValue, sb)
			)
		);
	}

	public void putEvaluationRequest(String script, boolean discardReturnValue) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(
			new Message(
				MessageType.REQUEST
				, Subject.RQ_EVALUATE
				, new RequestEvaluation(script, discardReturnValue, null)
			)
		);
	}

	public void putEvaluationRequest(String script, boolean discardReturnValue, Map<String, Object> bindings) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		SimpleBindings sb = null;
		if (bindings != null) {
			sb = new SimpleBindings(bindings);
			sb.put("R", this.rClient);
		}
		evaluationThread.putQueueItem(
			new Message(
				MessageType.REQUEST
				, Subject.RQ_EVALUATE
				, new RequestEvaluation(script, discardReturnValue, sb)
			)
		);
	}

	public void putInvokeFunctionRequest(String functionName, Object... arguments) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(
			new Message(
				MessageType.REQUEST
				, Subject.RQ_INVOKE_FUNCTION
				, new RequestInvokeFunction(functionName, arguments)
			)
		);
	}

	public void putInvokeMethodRequest(String objectName, String methodName, Object... arguments) throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		evaluationThread.putQueueItem(
			new Message(
				MessageType.REQUEST
				, Subject.RQ_INVOKE_METHOD
				, new RequestInvokeMethod(objectName, methodName, arguments)
			)
		);
	}

	void putQueueItem(JavaToR j2r) throws InterruptedException {
		queue.put(j2r);
	}
	
	public boolean removeScriptEngineValue(String key) {
		if (!initialized)
			throw new IllegalStateException();
		return (engine.getBindings(ScriptContext.ENGINE_SCOPE).remove(key) != null);
	}
	
	public void setArrayOrder(ArrayOrder value) {
		arrayOrder = value;
	}
	
	public void setScriptEngineValue(String key, boolean value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, boolean[] value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, boolean[][] value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, byte value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, byte[] value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, byte[][] value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, double value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, double[] value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, double[][] value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, int value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, int[] value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, int[][] value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, List<?> value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, Map<?, ?> value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, Object value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, String value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, String[] value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}

	public void setScriptEngineValue(String key, String[][] value) {
		if (!initialized)
			throw new IllegalStateException();
		engine.put(key, value);
	}
	
	public void setStandardOutputMode(StandardOutputMode value) {
		standardOutputMode = value;
		switch (value) {
		case CONSOLE:
			if (defaultContextWriter != null) {
				engine.getContext().setWriter(defaultContextWriter);
				defaultContextWriter = null;
			}
			break;
		case QUIET:
			if (defaultContextWriter == null)
				defaultContextWriter = engine.getContext().getWriter();
			engine.getContext().setWriter(new SilentWriter());
			break;
		case BUFFER:
			if (defaultContextWriter == null)
				defaultContextWriter = engine.getContext().getWriter();
			if (!StringWriter.class.equals((engine.getContext().getWriter().getClass())))
				engine.getContext().setWriter(new StringWriter(STANDARD_OUTPUT_BUFFER_SIZE_DEFAULT));
			break;
		}
	}

	/*
	 * Always call terminate to shutdown the associated thread.
	 */
	public void terminate() throws InterruptedException {
		if (!initialized)
			return;
		evaluationThread.putQueueItem(new Message(MessageType.REQUEST, Subject.RQ_QUIT, null));
		defaultContextWriter = null;
		engine = null;
		evaluationThread = null;
		manager = null;
		rClient = null;
		initialized = false;
	}

	public int waitForEvaluation() throws InterruptedException {
		if (!initialized)
			throw new IllegalStateException();
		/*
		 * Notice that 'getScriptEngineValue' also updates 'response'. Even
		 * though this library uses multi-threading, execution is actually
		 * synchronous, so 'response' will never be updated asynchronously.
		 */
		return response.initializeFrom(queue.take());
	}

}

package org.fgilbert.jsr223;

import java.lang.Runnable;
import java.lang.Thread;
import java.util.concurrent.ArrayBlockingQueue;

import javax.script.Bindings;
import javax.script.CompiledScript;
import javax.script.Invocable;
import javax.script.ScriptEngine;

import org.fgilbert.jdx.JavaToR;
import org.fgilbert.jsr223.Message.Subject;

class EvaluationThread implements Runnable {

	private Controller controller;
	private ScriptEngine engine;
	private Invocable invocable;
	private ArrayBlockingQueue<Message> queue;
	private boolean started;
	private Thread thread;

	{
		queue = new ArrayBlockingQueue<Message>(1);
	}

	EvaluationThread(Controller controller, javax.script.ScriptEngine engine) {
		this.controller = controller;
		this.engine = engine;
		try {
			invocable = (Invocable) engine;
		} catch (Throwable e) {
		}
	}

	void eval(RequestEvaluation request) throws InterruptedException {
		try {
			CompiledScript compiledScript = request.getCompiledScript();
			Bindings bindings = request.getBindings();
			Object result = null;
			if (compiledScript == null) {
				result = (bindings == null) ? engine.eval(request.getScript()) : engine.eval(request.getScript(), bindings);
			} else {
				result = (bindings == null) ? compiledScript.eval() : compiledScript.eval(bindings);
			}
			controller.putQueueItem(request.getDiscardReturnValue() ? new JavaToR(null) : new JavaToR(result, controller.getArrayOrder()));
		} catch (Throwable e) {
			controller.putQueueItem(new JavaToR(e));
		}
	}

	void invokeFunction(RequestInvokeFunction request) throws InterruptedException {
		try {
			if (invocable == null)
				throw new RuntimeException("The script engine does not support the invocable interface.");
			controller.putQueueItem(
					new JavaToR(invocable.invokeFunction(request.getFunctionName(), request.getArguments()), controller.getArrayOrder())
			);
		} catch (Throwable e) {
			controller.putQueueItem(new JavaToR(e));
		}
	}

	void invokeMethod(RequestInvokeMethod request) throws InterruptedException {
		try {
			if (invocable == null)
				throw new RuntimeException("The script engine does not support the invocable interface.");
			Object object = engine.get(request.getObjectName());
			if (object == null)
				throw new RuntimeException(
						String.format("An object with identifier '%s' could not be found.", request.getObjectName())
				);
			controller.putQueueItem(
					new JavaToR(invocable.invokeMethod(object, request.getMethodName(), request.getArguments()), controller.getArrayOrder())
			);
		} catch (Throwable e) {
			controller.putQueueItem(new JavaToR(e));
		}
	}

	Message getQueueItem() throws InterruptedException {
		return queue.take();
	}

	boolean isStarted() {
		return started;
	}

	void processRequest(Message message) throws InterruptedException {
		switch (message.getSubject()) {
		case RQ_EVALUATE:
			this.eval((RequestEvaluation) message.getData());
			break;
		case RQ_INVOKE_FUNCTION:
			this.invokeFunction((RequestInvokeFunction) message.getData());
			break;
		case RQ_INVOKE_METHOD:
			this.invokeMethod((RequestInvokeMethod) message.getData());
			break;
		default:
			throw new RuntimeException(String.format("Unexpected message subject '%s'.", message.getSubject()));
		}
	}

	void putQueueItem(Message message) throws InterruptedException {
		queue.put(message);
	}

	// Implementation of Runnable interface. Do not call directly. Use 'start'
	// instead.
	public void run() {
		Message message = null;
		do {
			try {
				message = queue.take();
				this.processRequest(message);
			} catch (Throwable e) {
				boolean putComplete = false;
				do {
					try {
						controller.putQueueItem(new JavaToR(e, controller.getArrayOrder()));
						putComplete = true;
					} catch (InterruptedException e1) {
					}
				} while (!putComplete);
			}
		} while (message.getSubject() != Subject.RQ_QUIT);
	}

	void start() {
		if (started)
			throw new RuntimeException("The evaluation thread has already been started.");
		thread = new Thread(this);
		thread.start();
		started = true;
	}

}

package org.fgilbert.jsr223;

import org.fgilbert.jdx.JavaToR;
import org.fgilbert.jsr223.Message.MessageType;
import org.fgilbert.jsr223.Message.Subject;

public class RClient {

	private Controller controller;
	private EvaluationThread evaluationThread;
	
	// Constructor is visible to package only.
	RClient(Controller controller, EvaluationThread evaluationThread) {
		this.controller = controller;
		this.evaluationThread = evaluationThread;
	}
	
	public Object eval(String script) throws Throwable {
		controller.putQueueItem(new JavaToR(new CallbackEvaluation(script), Controller.CALLBACK_EVALUATION));
		Message message = null;
		do {
			message = evaluationThread.getQueueItem();
			if (message.getMessageType() == MessageType.RESPONSE) {
				if (message.getSubject() == Subject.RSP_ERROR)
					throw new RuntimeException((String) message.getData());
				break;
			} else {
				evaluationThread.processRequest(message);
			}
		} while(true);
		return message.getData();
	}
	
	public Object get(String key) throws Throwable {
		controller.putQueueItem(new JavaToR(new CallbackGetValue(key), Controller.CALLBACK_GET_VALUE));
		Message message = evaluationThread.getQueueItem();
		if (message.getSubject() == Subject.RSP_ERROR)
			throw new RuntimeException((String) message.getData());
		return message.getData();
	}
	
	public void set(String key, Object value) throws Throwable {
		controller.putQueueItem(new JavaToR(new CallbackSetValue(key, new JavaToR(value, controller.getArrayOrder())), Controller.CALLBACK_SET_VALUE));
		Message message = evaluationThread.getQueueItem();
		if (message.getSubject() == Subject.RSP_ERROR)
			throw new RuntimeException((String) message.getData());
	}

}

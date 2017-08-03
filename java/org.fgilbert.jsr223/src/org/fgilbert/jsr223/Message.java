package org.fgilbert.jsr223;

class Message {

	public enum MessageType {
		REQUEST, RESPONSE;
	}
	
	public enum Subject {
		RQ_EVALUATE, RQ_INVOKE_FUNCTION, RQ_INVOKE_METHOD, RQ_QUIT, RSP_ERROR, RSP_OK;
	}
	
	private Object data;
	private MessageType messageType;
	private Subject subject;
	
	public Message(MessageType messageType, Subject subject, Object data) {
		this.data = data;
		this.messageType = messageType;
		this.subject = subject;
		// TODO Auto-generated constructor stub
	}

	public Object getData() {
		return data;
	}

	public void setData(Object data) {
		this.data = data;
	}

	public MessageType getMessageType() {
		return messageType;
	}

	public void setMessageType(MessageType messageType) {
		this.messageType = messageType;
	}

	public Subject getSubject() {
		return subject;
	}

	public void setSubject(Subject subject) {
		this.subject = subject;
	}

	@Override
	public String toString() {
		return "Message [messageType=" + messageType + ", subject=" + subject + ", data=" + data + "]";
	}

}

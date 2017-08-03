package org.fgilbert.jsr223;

import java.io.IOException;
import java.io.Writer;

class SilentWriter extends Writer {

	public SilentWriter() {
	}

	public SilentWriter(Object lock) {
		super(lock);
	}

	@Override
	public void close() throws IOException {
	}

	@Override
	public void flush() throws IOException {
	}

	@Override
	public void write(char[] cbuf, int off, int len) throws IOException {
	}

}

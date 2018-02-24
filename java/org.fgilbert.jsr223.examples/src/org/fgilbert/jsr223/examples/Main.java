package org.fgilbert.jsr223.examples;

public class Main {

	public Main() {
		// TODO Auto-generated constructor stub
	}

	public static void main(String[] args) {
		double[] a = {1,2,3};
		double[] b = null;
		
		b = a.clone();
		System.out.println(a[1]);
		b[1] = 3;
		System.out.println(a[1]);

		
	}
}

package org.fgilbert.jsr223.examples;

public class Examples {
	
	private static long bellNumberInner(long n, long k) {
		if (n == 0 && k == 0)
			return 1;
		if (n == 0 || k == 0)
			return 0;
		return k * bellNumberInner(n - 1, k) + bellNumberInner(n - 1, k - 1);
	}
	
	public static long bellNumber(long n) {
		long sum = 0;
		for (long k = 0; k <= n; k++)
			sum += bellNumberInner(n, k);
		return sum;
	}
	
}

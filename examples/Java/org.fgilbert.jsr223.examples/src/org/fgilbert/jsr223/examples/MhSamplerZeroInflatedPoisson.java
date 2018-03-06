package org.fgilbert.jsr223.examples;

import static java.lang.Math.*;

public class MhSamplerZeroInflatedPoisson extends MhSamplerUnivariateProposal {
	private double alpha, beta, theta, kappa;
	private double dataLength, dataSum, dataZeroCount, dataPositiveCount;

	public MhSamplerZeroInflatedPoisson(double alpha, double beta, double theta, double kappa, int[] data) {
	    this.alpha = alpha;
	    this.beta = beta;
	    this.theta = theta;
	    this.kappa = kappa;

	    dataLength = data.length;
	    for (int i = 0; i < dataLength; i++) {
	      dataSum += data[i];
	      if (data[i] == 0)
	        dataZeroCount++;
	    }
	    dataPositiveCount = dataLength - dataZeroCount;
	}

	@Override
	public double logPosterior(double[] values) {
		double pi = values[0];
		double lambda = values[1];
		
		if (pi <= 0 || pi >= 1 || lambda < 0)
			return Double.NEGATIVE_INFINITY;
		return (alpha - 1) * log(pi) + (beta - 1) * log(1 - pi) +
			(theta - 1) * log(lambda) - kappa * lambda +
			dataZeroCount * log(pi + (1 - pi) * exp(-lambda)) +
			dataPositiveCount * log((1 - pi) * exp(-lambda)) +
			dataSum * log(lambda);
	}

}

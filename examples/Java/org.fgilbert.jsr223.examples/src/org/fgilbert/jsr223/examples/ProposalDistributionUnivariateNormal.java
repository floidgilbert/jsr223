package org.fgilbert.jsr223.examples;

import static java.lang.Math.*;
import org.apache.commons.math3.distribution.UniformRealDistribution;
import org.apache.commons.math3.random.SynchronizedRandomGenerator;
import org.apache.commons.math3.random.Well19937c;

public class ProposalDistributionUnivariateNormal implements ProposalDistributionUnivariate {

	private double standardDeviation;
	private double variance;
	private UniformRealDistribution unif = new UniformRealDistribution(new SynchronizedRandomGenerator(new Well19937c()), 0, 1);
	
	public ProposalDistributionUnivariateNormal(double variance) {
		super();
		this.variance = variance;
		this.standardDeviation = sqrt(variance);
	}
	
	public double density(double x, double given) {
		return 1 / sqrt(2 * PI * variance) * exp(-pow((x - given), 2) / (2 * variance));
	}

	public double logDensity(double x, double given) {
		return -log(sqrt(2 * PI * variance)) -pow((x - given), 2) / (2 * variance);
	}

	public double sample(double state) {
		return state + standardDeviation * sqrt(-2 * log(unif.sample())) * cos(2 * PI * unif.sample());
	}
}

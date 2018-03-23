package org.fgilbert.jsr223.examples;

import java.util.LinkedHashMap;

public interface Sampler {

	public double logPosterior(double[] values);
	
	public LinkedHashMap<String, Object> sample(double[][] startingValues, ProposalDistributionUnivariate[] proposalDistributions, int iterations, int discard, int threads);
	
}

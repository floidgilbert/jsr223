package org.fgilbert.jsr223.examples;

import static java.lang.Math.*;
import java.util.LinkedHashMap;
import org.apache.commons.math3.distribution.UniformRealDistribution;
import java.time.Duration;
import java.time.Instant;

public abstract class MhSamplerUnivariateProposal {

	public abstract double logPosterior(double[] values);

	public LinkedHashMap<String, Object> run(double[][] startingValues, ProposalDistributionUnivariate[] proposalDistributions, int iterations) {
		Instant start = Instant.now();
		
		/*
		 * Validate parameters. 
		 */
		int parameterCount = proposalDistributions.length;
		if (parameterCount == 0)
			throw new RuntimeException("Invalid number of proposal distributions. There is a one-to-one relationship between the number of parameters and proposal distributions.");
		if (startingValues[0].length != parameterCount)
			throw new RuntimeException("This statement must be true 'startingValues[x].length == proposalDistributions.length'. That is, there must be a proposal distribution for each parameter.");
		if (iterations < 1)
			throw new RuntimeException("The value 'iterations' must be greater than zero.");
		
		/*
		 * Initialize data structures.
		 */
		UniformRealDistribution unif = new UniformRealDistribution();
		// int chainCount = startingValues.length;
		// double[][][] chains = new double[chainCount][iterations][parameterCount];
		double[][] chains = new double[iterations][parameterCount];
		int[] proposalsAccepted = new int[parameterCount];
		double[] state = null;
		double[] proposal = null;
		double probabilityRatio;
		
		/*
		 * Run MCMC.
		 */
		chains[0] = startingValues[0].clone();
		for (int i = 1; i < iterations; i++) {
			state = chains[i - 1].clone();
			proposal = state.clone();
			for (int j = 0; j < parameterCount; j++) {
				proposal[j] = proposalDistributions[j].sample(state[j]);
				probabilityRatio = (logPosterior(proposal) - proposalDistributions[j].density(proposal[j], state[j])) +
						(logPosterior(state) - proposalDistributions[j].density(state[j], proposal[j]));
				if (probabilityRatio >= log(unif.sample())) {
					state[j] = proposal[j];
					proposalsAccepted[j]++;
				} else {
					proposal[j] = state[j];
				}
			}
			chains[i] = state.clone(); // IMPORTANT: clone() is a shallow copy. Works for one-dimensional native arrays.
		}
		
		/*
		 * Return results.
		 */
		double[] acceptanceRatios = new double[parameterCount];
		for (int j = 0; j < parameterCount; j++)
			acceptanceRatios[j] = proposalsAccepted[j] / iterations;
		LinkedHashMap<String, Object> m = new LinkedHashMap<String, Object>();
		m.put("accepted", proposalsAccepted);
		m.put("acceptance ratios", acceptanceRatios);
		m.put("chains", chains);
		m.put("milliseconds", Duration.between(start, Instant.now()).toMillis());
		m.put("iterations", iterations);
		return m;
	}

}

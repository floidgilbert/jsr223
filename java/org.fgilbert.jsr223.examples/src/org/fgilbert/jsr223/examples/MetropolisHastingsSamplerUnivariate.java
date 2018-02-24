package org.fgilbert.jsr223.examples;

import java.util.LinkedHashMap;
import org.apache.commons.math3.distribution.UniformRealDistribution;
import java.time.Duration;
import java.time.Instant;
import java.lang.Math;

public abstract class MetropolisHastingsSamplerUnivariate {

	public MetropolisHastingsSamplerUnivariate() {}
	
	public abstract double logPosterior(double[] parameters);
	
	public LinkedHashMap<String, Object> run(double[][] startingValues, ProposalDistributionUnivariate[] proposalDistributions, int iterations) {
		///check parameters
		Instant start = Instant.now();
		UniformRealDistribution unif = new UniformRealDistribution();
		int parameterCount = proposalDistributions.length;
		// int chainCount = startingValues.length;
		// double[][][] chains = new double[chainCount - 1][iterations - 1][parameterCount - 1];
		double[][] chains = new double[iterations - 1][parameterCount - 1];
		int[] proposalsAccepted = new int[parameterCount - 1];
		double[] state = null;
		double[] proposal = null;
		double probabilityRatio;
		
		chains[0] = startingValues[0].clone();
		for (int i = 1; i < iterations; i++) {
			state = chains[i - 1].clone();
			proposal = state.clone();
			for (int j = 0; j < parameterCount; j++) {
				proposal[j] = proposalDistributions[j].sample(state[j]);
				probabilityRatio = (logPosterior(proposal) - proposalDistributions[j].density(proposal, state)) +
						(logPosterior(state) - proposalDistributions[j].density(state, proposal));
				if (probabilityRatio >= Math.log(unif.sample())) {
					state[j] = proposal[j];
					proposalsAccepted[j]++;
				} else {
					proposal[j] = state[j];
				}
			}
			/// try with other copy methods besides clone. Array.copy, System.arraycopy. http://www.javapractices.com/topic/TopicAction.do?Id=3. time them.
			chains[i] = state.clone(); // IMPORTANT: clone() is a shallow copy. Works for one-dimensional native arrays.
		}
		double[] acceptanceRatios = new double[parameterCount - 1];
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

package org.fgilbert.jsr223.examples;

import java.util.LinkedHashMap;
import org.apache.commons.math3.distribution.UniformRealDistribution;
import java.time.Duration;
import java.time.Instant;
import java.lang.Math;

public abstract class MetropolisSamplerUnivariateProposals {

	public abstract class ProposalDistribution {
		public abstract double sample(double previousValue);
	}
	
	public MetropolisSamplerUnivariateProposals() {}
	
	public abstract double logPosterior(double[] parameters);
	
	public LinkedHashMap<String, Object> run(double[][] startingValues, ProposalDistribution[] proposalDistributions, int iterations) {
		///check parameters
		Instant start = Instant.now();
		UniformRealDistribution unif = new UniformRealDistribution();
		int parameterCount = proposalDistributions.length;
		// int chainCount = startingValues.length;
		// double[][][] chains = new double[chainCount - 1][iterations - 1][parameterCount - 1];
		double[][] chains = new double[iterations - 1][parameterCount - 1];
		int[] proposalsAccepted = new int[parameterCount - 1];
		double[] thetaTemp = new double[parameterCount - 1];
		double probabilityRatio;
		
		for (int j = 0; j < parameterCount; j++)
			chains[0][j] = startingValues[0][j];
		
		for (int i = 1; i < iterations; i++) {
			for (int j = 0; j < parameterCount; j++)
				thetaTemp[j] = chains[i - 1][j];
			for (int j = 0; j < parameterCount; j++) {
				probabilityRatio = logPosterior(thetaTemp);
				thetaTemp[j] = proposalDistributions[j].sample(thetaTemp[j]);
				probabilityRatio = logPosterior(thetaTemp) - probabilityRatio;
				if (probabilityRatio >= Math.log(unif.sample())) {
					proposalsAccepted[j]++;
				} else {
					thetaTemp[j] = chains[i - 1][j];
				}
			}
			for (int j = 0; j < parameterCount; j++)
				chains[i][j] = thetaTemp[j];
		}
		double[] acceptanceRatios = new double[parameterCount - 1];
		for (int j = 0; j < parameterCount; j++)
			acceptanceRatios[j] = proposalsAccepted[j] / iterations;
		
		LinkedHashMap<String, Object> m = new LinkedHashMap<String, Object>();
		m.put("accepted", proposalsAccepted);
		m.put("chains", chains);
		m.put("duration", Duration.between(start, Instant.now()));
		m.put("iterations", iterations);
		return m;
	}

}

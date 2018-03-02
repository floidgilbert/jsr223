package org.fgilbert.jsr223.examples;

import static java.lang.Math.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import org.apache.commons.math3.distribution.UniformRealDistribution;
import java.time.Duration;
import java.time.Instant;

public abstract class MhSamplerUnivariateProposal {

	public abstract double logPosterior(double[] values);
	
	private class Chain implements Runnable {
		private int iterations;
		private int parameterCount;
		private ProposalDistributionUnivariate[] proposalDistributions;
		private double[] startingValues;
		
		public LinkedHashMap<String, Object> result = null; 
		
		public Chain(double[] startingValues, ProposalDistributionUnivariate[] proposalDistributions, int iterations) {
			this.startingValues = startingValues;
			this.proposalDistributions = proposalDistributions;
			this.iterations = iterations;
			this.parameterCount = proposalDistributions.length;
		}

		@Override
		public void run() {
			Instant start = Instant.now();
			/*
			 * Initialize data structures.
			 */
			UniformRealDistribution unif = new UniformRealDistribution();
			double[][] chains = new double[iterations][parameterCount];
			int[] proposalsAccepted = new int[parameterCount];
			double[] state = null;
			double[] proposal = null;
			double probabilityRatio;
			
			/*
			 * Run MCMC.
			 */
			chains[0] = startingValues.clone();
			for (int i = 1; i < iterations; i++) {
				state = chains[i - 1].clone();
				proposal = state.clone();
				for (int j = 0; j < parameterCount; j++) {
					proposal[j] = proposalDistributions[j].sample(state[j]);
					probabilityRatio = (logPosterior(proposal) - proposalDistributions[j].density(proposal[j], state[j])) -
							(logPosterior(state) - proposalDistributions[j].density(state[j], proposal[j]));
					if (probabilityRatio >= log(unif.sample())) {
						state[j] = proposal[j];
						proposalsAccepted[j]++;
					} else {
						proposal[j] = state[j];
					}
				}
				chains[i] = state.clone(); // IMPORTANT: clone() is a shallow copy. But, for one-dimensional native arrays, it is the same as a deep copy.
			}
			
			/*
			 * Return results.
			 */
			double[] acceptanceRatios = new double[parameterCount];
			for (int j = 0; j < parameterCount; j++)
				acceptanceRatios[j] = (double) proposalsAccepted[j] / iterations;
			result = new LinkedHashMap<String, Object>();
			result.put("accepted", proposalsAccepted);
			result.put("acceptance-ratios", acceptanceRatios);
			result.put("chains", chains);
			result.put("iterations", iterations);
			result.put("milliseconds", Duration.between(start, Instant.now()).toMillis());
			result.put("starting-values", startingValues);
		}
		
	}
	
	public ArrayList<LinkedHashMap<String, Object>> sample(double[][] startingValues, ProposalDistributionUnivariate[] proposalDistributions, int iterations, int threads) throws InterruptedException {
		
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
		if (threads < 1)
			throw new RuntimeException("The value 'threads' must be greater than zero.");

		/*
		 * Run chains
		 */
		Chain[] chains = new Chain[startingValues.length];
		ExecutorService ex = Executors.newFixedThreadPool(threads);
		for (int i = 0; i < startingValues.length; i++) {
			chains[i] = new Chain(startingValues[i], proposalDistributions, iterations); 
			ex.submit(chains[i]);
		}
		ex.shutdown();
		ex.awaitTermination(Long.MAX_VALUE, TimeUnit.DAYS);
		ArrayList<LinkedHashMap<String, Object>> a = new ArrayList<LinkedHashMap<String, Object>>(chains.length);
		for (int i = 0; i < startingValues.length; i++)
			a.add(chains[i].result); 
		return a;
	}
	
}

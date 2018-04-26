package org.fgilbert.jsr223.examples;

/* 
 * Generic Metropolis-Hastings sampler with univariate proposal densities 
 */

import static java.lang.Math.*;

import java.util.LinkedHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import org.apache.commons.math3.distribution.UniformRealDistribution;

public abstract class MetropolisHastingsSamplerUnivariateProposal implements Sampler {

	public abstract double logPosterior(double[] values);
	
	private class MCMC implements Runnable {
		private int discard;
		private int iterations;
		private int parameterCount;
		private ProposalDistributionUnivariate[] proposalDistributions;
		private double[] startingValues;
		
		public double[] acceptanceRates; 
		public double[][] chains; 
		
		public MCMC(double[] startingValues, ProposalDistributionUnivariate[] proposalDistributions, int iterations, int discard) {
			this.startingValues = startingValues;
			this.proposalDistributions = proposalDistributions;
			this.iterations = iterations;
			this.discard = discard;
			this.parameterCount = proposalDistributions.length;
		}

		@Override
		public void run() {
			/*
			 * Initialize data structures.
			 */
			UniformRealDistribution unif = new UniformRealDistribution();
			chains = new double[iterations - discard][parameterCount];
			int[] proposalsAccepted = new int[parameterCount];
			double[] state = startingValues.clone();
			double[] proposal = startingValues.clone();
			double probabilityRatio;
			double logPosteriorProposal;
			double logPosteriorState = logPosterior(startingValues);
			
			/*
			 * Run MCMC.
			 */
			if (discard == 0)
				chains[0] = startingValues.clone();
			for (int i = 1; i < iterations; i++) {
				for (int j = 0; j < parameterCount; j++) {
					proposal[j] = proposalDistributions[j].sample(state[j]);
					logPosteriorProposal = logPosterior(proposal);
					
					probabilityRatio = (logPosteriorProposal - proposalDistributions[j].logDensity(proposal[j], state[j])) -
							(logPosteriorState - proposalDistributions[j].logDensity(state[j], proposal[j]));
					if (probabilityRatio >= log(unif.sample())) {
						state[j] = proposal[j];
						logPosteriorState = logPosteriorProposal;
						proposalsAccepted[j]++;
					} else {
						proposal[j] = state[j];
					}
				}
				if (i >= discard)
					chains[i - discard] = state.clone(); // IMPORTANT: clone() is a shallow copy. But, for one-dimensional native arrays, it is the same as a deep copy.
			}
			
			/*
			 * Return results.
			 */
			acceptanceRates = new double[parameterCount];
			for (int j = 0; j < parameterCount; j++)
				acceptanceRates[j] = (double) proposalsAccepted[j] / iterations;
		}
		
	}
	
	public LinkedHashMap<String, Object> sample(double[][] startingValues, ProposalDistributionUnivariate[] proposalDistributions, int iterations, int discard, int threads) {
		
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
		if (discard < 0 || discard >= iterations)
			throw new RuntimeException("The value 'discard' must be zero or greater and less than 'iterations'.");
		if (threads < 1)
			throw new RuntimeException("The value 'threads' must be greater than zero.");

		/*
		 * Run chains
		 */
		MCMC[] mcmc = new MCMC[startingValues.length];
		ExecutorService ex = Executors.newFixedThreadPool(threads);
		for (int i = 0; i < startingValues.length; i++) {
			// Pass the arguments to each MCMC object to keep this.sample() thread-safe.
			mcmc[i] = new MCMC(startingValues[i], proposalDistributions, iterations, discard); 
			ex.submit(mcmc[i]);
		}
		ex.shutdown();
		try {
			ex.awaitTermination(Long.MAX_VALUE, TimeUnit.DAYS);
		} catch (Throwable e) {
			throw new RuntimeException(e);
		}
		double[][] acceptanceRates = new double[mcmc.length][];
		double[][][] chains = new double[mcmc.length][][];
		for (int i = 0; i < mcmc.length; i++) {
			acceptanceRates[i] = mcmc[i].acceptanceRates;
			chains[i] = mcmc[i].chains;
		}
		LinkedHashMap<String, Object> m = new LinkedHashMap<String, Object>(2);
		m.put("acceptance_rates", acceptanceRates);
		m.put("chains", chains);
		return m;
	}
	
}

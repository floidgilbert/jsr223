package org.fgilbert.jsr223.examples;

public abstract class ProposalDistributionUnivariate {

	public abstract double density(double x, double given);
	
	public abstract double sample(double state);
}

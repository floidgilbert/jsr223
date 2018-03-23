package org.fgilbert.jsr223.examples;

public interface ProposalDistributionUnivariate {

	double density(double x, double given);
	
	double logDensity(double x, double given);

	double sample(double state);

}
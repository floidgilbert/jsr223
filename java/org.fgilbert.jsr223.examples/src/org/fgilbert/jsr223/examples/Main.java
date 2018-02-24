package org.fgilbert.jsr223.examples;

import org.fgilbert.jsr223.examples.MetropolisSamplerUnivariateProposals.ProposalDistribution;

public class Main {

	public Main() {
		// TODO Auto-generated constructor stub
	}

	public static void main(String[] args) {

		///probably do as a separate inner class or something instead? need to use the kind (local?) that will inherit the stuff around it.
		MetropolisSamplerUnivariateProposals m = new MetropolisSamplerUnivariateProposals() {
			@Override
			public double logPosterior(double[] parameters) {
				double pi = parameters[0];
				double lambda = parameters[1];
				return 0;
			}
		};
		
		ProposalDistribution p = new m.ProposalDistribution() {
			@Override
			public double sample(double previousValue) {
				// TODO Auto-generated method stub
				return 0;
			}
		};
		
	}
}

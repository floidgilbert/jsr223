package nodist;

import java.util.LinkedHashMap;
import org.fgilbert.jsr223.examples.MhSamplerUnivariateProposal;
import org.fgilbert.jsr223.examples.ProposalDistributionUnivariate;
import org.fgilbert.jsr223.examples.ProposalDistributionUnivariateNormal;
import org.apache.commons.math3.distribution.MultivariateNormalDistribution;

public class Main {

	private static class MetropolisHastingsSampler extends MhSamplerUnivariateProposal {

		private MultivariateNormalDistribution mvn = new MultivariateNormalDistribution(new double[] {0, 0}, new double[][] {{1, 0}, {0, 1}});
		
		@Override
		public double logPosterior(double[] values) {
			return mvn.density(values);
		}
	}
	
	public static void main(String[] args) {
		MhSamplerUnivariateProposal mh = new Main.MetropolisHastingsSampler();
		ProposalDistributionUnivariate[] pd = {
				new ProposalDistributionUnivariateNormal(1.2), 
				new ProposalDistributionUnivariateNormal(0.2)
		};
		LinkedHashMap<String, Object> m = mh.run(
				new double[][] {{-3, -3}, {3, 3}, {-3, 3}},
				pd,
				10000
		);
		System.out.println(m.get("milliseconds"));
		double[][] chains = (double[][]) m.get("chains");
		for (int i = 0; i < 10; i++)
			System.out.println(java.util.Arrays.toString(chains[i]));
	}
}

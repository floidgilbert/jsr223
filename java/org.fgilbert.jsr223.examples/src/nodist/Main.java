package nodist;

import static java.lang.Math.*;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import org.fgilbert.jsr223.examples.MhSamplerUnivariateProposal;
import org.fgilbert.jsr223.examples.ProposalDistributionUnivariate;
import org.fgilbert.jsr223.examples.ProposalDistributionUnivariateNormal;
//import org.apache.commons.math3.distribution.MultivariateNormalDistribution;

public class Main {

	private static class Sampler extends MhSamplerUnivariateProposal {
		  private double alpha, beta, theta, kappa;
		  private int dataLength, dataSum, dataZeroCount, dataPositiveCount;

		  public Sampler(double alpha, double beta, double theta, double kappa, int[] data) {
		    this.alpha = alpha;
		    this.beta = beta;
		    this.theta = theta;
		    this.kappa = kappa;

		    dataLength = data.length;
		    for (int i = 0; i < dataLength; i++) {
		      dataSum += data[i];
		      if (data[i] == 0)
		        dataZeroCount++;
		      else
		        dataPositiveCount++;
		    }
		  }

			@Override
			public double logPosterior(double[] values) {
		    double pi = values[0];
		    double lambda = values[1];
		    if (pi <= 0 || pi >= 1 || lambda < 0)
		      return Double.NEGATIVE_INFINITY;
		    return (alpha - 1) * log(pi) +
		      (beta - 1) * log(1 - pi) +
		      (theta - 1) * log(lambda) +
		      -kappa * lambda +
		      dataZeroCount * log(pi + (1 - pi) * exp(-lambda)) +
		      dataPositiveCount * log((1 - pi) * exp(-lambda)) +
		      dataSum * log(lambda);
			}
	}
	
	public static void main(String[] args) throws InterruptedException {
		int[] data = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 5};
		MhSamplerUnivariateProposal mh = new Main.Sampler(1, 1, 2, 1, data);
		ProposalDistributionUnivariate[] pd = {
				new ProposalDistributionUnivariateNormal(0.25), 
				new ProposalDistributionUnivariateNormal(1.44)
		};
		ArrayList<LinkedHashMap<String, Object>> s = mh.sample(
				new double[][] {{0.001, 0.001}, {0.001, 0.999}, {0.999, 0.001}, {0.999, 0.999}},
				pd,
				10000,
				4
		);
		for (int i = 0; i < s.size(); i++) {
			LinkedHashMap<String, Object> m = s.get(i);
			System.out.println(m.get("milliseconds"));
			System.out.println(java.util.Arrays.toString((double[]) m.get("acceptance-ratios")));
			double[][] chains = (double[][]) m.get("chains");
			for (int j = 0; j < 10; j++)
				System.out.println(java.util.Arrays.toString(chains[i]));
			System.out.println(">>>");
		}
	}
}


//public class Main {
//
//	private static class MetropolisHastingsSampler extends MhSamplerUnivariateProposal {
//
//		private MultivariateNormalDistribution mvn = new MultivariateNormalDistribution(new double[] {0, 0}, new double[][] {{1, 0}, {0, 1}});
//		
//		@Override
//		public double logPosterior(double[] values) {
//			return mvn.density(values);
//		}
//	}
//	
//	public static void main(String[] args) {
//		MhSamplerUnivariateProposal mh = new Main.MetropolisHastingsSampler();
//		ProposalDistributionUnivariate[] pd = {
//				new ProposalDistributionUnivariateNormal(1.2), 
//				new ProposalDistributionUnivariateNormal(0.2)
//		};
//		LinkedHashMap<String, Object> m = mh.run(
//				new double[][] {{-3, -3}, {3, 3}, {-3, 3}},
//				pd,
//				10000
//		);
//		System.out.println(m.get("milliseconds"));
//		double[][] chains = (double[][]) m.get("chains");
//		for (int i = 0; i < 10; i++)
//			System.out.println(java.util.Arrays.toString(chains[i]));
//	}
//}

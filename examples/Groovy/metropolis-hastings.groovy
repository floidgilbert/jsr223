/*
 * This script is sourced by 'metropolis-hastings.R'
 */

import static java.lang.Math.*;
import org.fgilbert.jsr223.examples.MhSamplerUnivariateProposal;
import org.fgilbert.jsr223.examples.ProposalDistributionUnivariateNormal;

public class Sampler extends MhSamplerUnivariateProposal {
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

ProposalDistributionUnivariateNormal[] pd = new ProposalDistributionUnivariateNormal[proposalVariances.length];
for (int i = 0; i < proposalVariances.length; i++)
  pd[i]	= new ProposalDistributionUnivariateNormal(proposalVariances[i]);

Sampler mh = new Sampler(alpha, beta, theta, kappa, data);
mh.sample(startingValues, pd, iterations, threads);

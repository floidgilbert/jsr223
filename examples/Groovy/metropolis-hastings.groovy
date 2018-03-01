/*
 * This script is sourced by 'metropolis-hastings.R' See that script for an
 * overview. We follow Java syntax very formally in this script.
 */

import static java.lang.Math.*;
import org.fgilbert.jsr223.examples.MhSamplerUnivariateProposal;
import org.fgilbert.jsr223.examples.ProposalDistributionUnivariateNormal;

/*
 * Extend the abstract class MhSamplerUnivariateProposal. While it is possible
 * to achieve this same functionality with anonymous classes or closures (a
 * Groovy construct similar to Java lambdas), we found that this implementation
 * improved performance by more than two times.
 *
 * The abstract class exposes one abstract method: logPosterior, which we must
 * implement.
 */
public class Sampler extends MhSamplerUnivariateProposal {
  private double alpha, beta, theta, kappa;
  private double dataLength, dataSum, dataZeroCount, dataPositiveCount;

  // Constructor for our subclass.
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
    }
    dataPositiveCount = dataLength - dataZeroCount
  }

  // Implement the abstract method logPosterior.
	@Override
	public double logPosterior(double[] values) {
    double pi = values[0];
    double lambda = values[1];
    if (pi <= 0 || pi >= 1 || lambda < 0)
      return Double.NEGATIVE_INFINITY;
    return (alpha - 1) * log(pi) + (beta - 1) * log(1 - pi) +
      (theta - 1) * log(lambda) - kappa * lambda +
      dataZeroCount * log(pi + (1 - pi) * exp(-lambda)) +
      dataPositiveCount * log((1 - pi) * exp(-lambda)) +
      dataSum * log(lambda);
	}
}

/*
 * Initialize an array of proposal distributions to pass to the sampler. The
 * ProposalDistributionUnivariateNormal class is an implementation of the
 * ProposalDistributionUnivariate interface. We are free to implement other
 * proposal distributions.
 */
ProposalDistributionUnivariateNormal[] pd =
    new ProposalDistributionUnivariateNormal[proposalVariances.length];
for (int i = 0; i < proposalVariances.length; i++)
  pd[i]	= new ProposalDistributionUnivariateNormal(proposalVariances[i]);

/*
 * Create a new instance of our subclass. Note that the parameters to the
 * constructor are the bindings dynamically passed in from the R script.
 */
Sampler mh = new Sampler(alpha, beta, theta, kappa, data);
mh.sample(startingValues, pd, iterations, threads)

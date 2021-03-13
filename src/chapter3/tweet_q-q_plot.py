#################################################
# Show the Q-Q plot of the inter-arrival times. #
#################################################

import scipy.stats as stats

stats.probplot(diffs, dist='expon', plot=pylab)
pylab.show()

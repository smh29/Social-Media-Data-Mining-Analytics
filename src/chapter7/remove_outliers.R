# The number of random numbers to be generated.
N = 10e6

# Generate pseudorandom numbers with a Gaussian distribution
# with a mean of 10, and standard deviation of 1.
normal.distribution = rnorm(N, mean=10, sd=1)

# Function to generate random variables according to a power-law distribution
# in the [x0, x1] interval, and with a power-law exponent of gamma.
# See http://mathworld.wolfram.com/RandomNumber.html
generate.powerlaw.distribution = function(sample.size, x0, x1, gamma) {
  return(((x1 ^ (gamma + 1) - x0 ^ (gamma + 1)) * runif(sample.size) +
        x0 ^ (gamma + 1)) ^ (1 / (gamma + 1)))
}

# Generate the random numbers following a power law, between 1 and 100,
# and with an exponent of -3.5.
powerlaw.distribution = generate.powerlaw.distribution(N, 1, 100, -3.5)

# Function to truncate the sample by removing the largest values from the
# sample. The list of thresholds (between 0 and 1) is passed to this function; it
# then calculates the means and standard deviations of the samples that remain
# after removing the largest values according to these fractions (if the
# threshold is 0.05, the top 5% of the sample items will be removed).
remove.top.values = function(sample, thresholds) {
  sample = sample[order(sample)]
  result = data.frame(top.removed=thresholds)
  result = ddply(result, .(top.removed), function(df) {
      remaining = sample[1 :
          floor(length(sample) * (1 - df$top.removed))]
      return(data.frame(
          mean=mean(remaining),
          sd=sd(remaining)
        ))
    })
  result = within(result, {
      rel.mean = mean / mean[top.removed == 0]
      rel.sd = sd / sd[top.removed == 0]
    })
  return(result)
}

# Set the thresholds to be between 0 and 0.9 in 0.05 increments.
thresholds = seq(0, 0.9, by=0.05)
distribs.top.removed = data.frame()

# Run the "outlier" removal for the normal distribution.
distribs.top.removed = rbind(distribs.top.removed, data.frame(
    remove.top.values(normal.distribution, thresholds),
    distrib='Normal')
)

# Run the "outlier" removal for the power-law distribution.
distribs.top.removed = rbind(distribs.top.removed, data.frame(
    remove.top.values(powerlaw.distribution, thresholds),
    distrib='Power law')
)

gamma = -3.5
samples = data.frame()                  # This holds the sample means
for (sample.size in c(64, 256, 1024)) { # We take 3 different sample sizes
  means = c()                           # The means of the individual samples
  for (i in 1 : 1e5) {                  # How many samples we will take
    # Sampling from a PL distribution with the inverse transform
    x = (1 - runif(sample.size)) ^ (1 / (gamma + 1))
    mu = mean(x)
    means = c(means, mu)                # Collect the sample means
  }
  samples = rbind(samples,              # Accumulate all the sample means
    data.frame(sample.mean=means, sample.size=sample.size))
}

# Calculate the means & standard deviations of the sampling distributions
sampling.distribution = ddply(samples, .(sample.size), summarise,
  mean=mean(sample.mean), sd=sd(sample.mean))

# Plot the sampling distributions & their means with vertical lines
ggplot(samples, aes(x=sample.mean, group=sample.size)) +
  geom_density(alpha=0.3, fill='gray') +
  geom_vline(xintercept=sampling.distribution$mean) +
  xlim(c(1, 2.5)) + xlab('Sample means') + ylab('Density')

# The population standard deviation, comes from the calculations
population.sd = sqrt((gamma + 1) / (gamma + 3) - ((gamma + 1) / (gamma + 2)) ^ 2)

# To compare the measured and theoretical standard deviations
sampling.distribution = within(sampling.distribution,
  { theor.sd = population.sd / sqrt(sample.size) })

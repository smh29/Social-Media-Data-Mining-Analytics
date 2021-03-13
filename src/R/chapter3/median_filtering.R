library(robfilter)

# See "?adore.filter" for the meaning of the parameters.
filtered = adore.filter(data$count, min.width=300, max.width=350, p.test=80,
  extrapolate=TRUE)

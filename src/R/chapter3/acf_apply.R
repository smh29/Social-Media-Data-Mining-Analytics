# `detrended` contains the detrended time series, one point for each time index.
acf(detrended, lag.max=370)

# diff takes the differences between the elements of the vector at the
# given lag distances:
# diff(x, lag=L)[i] == x[i + L] - x[i]
acf(as.vector(diff(diff(detrended, lag=1), lag=7)), lag.max=370)

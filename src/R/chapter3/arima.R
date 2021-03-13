library(forecast)

len = length(data$count)
# For simplicity, we sample the data uniformly.
sampled_data = data$count[seq(1, len, 7)]

fitted_tps = arima(sampled_data,
  order=c(0, 1, 7),
  seasonal=list(order=c(0, 1, 2), period=52))

prediction = forecast(fitted_tps, 90)
plot(prediction)

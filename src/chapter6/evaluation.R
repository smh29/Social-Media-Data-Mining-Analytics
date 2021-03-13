pfit = predict(fit, newx=features_test, type='response')

# Print the AUC values for the 100 different models that glmnet creates.
sample_count = 1000000
for(i in 1 : 100){
    predictions = pfit[, i]
    print(i)
    predicted_values = predictions
    AUC_val = mean(
            sample(predicted_values[which(label_test == 1)],
                            sample_count, replace=TRUE) >
                    sample(predicted_values[which(label_test == 0)],
                            sample_count, replace=TRUE))
    print(AUC_val)
}

# Pick one model with a lambda parameter.
predicted_values = pfit[, 11]

# Interpretation of the model weights.
fit$beta[, 11]

# This prints the model coefficients.
#           age        gender  occupation.1  occupation.2  occupation.3
#  -0.085708632  -0.217505006   0.072805243   0.000000000   0.000000000
#
#  occupation.4  occupation.5  occupation.6  occupation.7  occupation.8
#   0.000000000   0.000000000   0.000000000   0.000000000  -0.002271373
#
#  occupation.9 occupation.10 occupation.11 occupation.12 occupation.13
#   0.000000000   0.000000000   0.146183185   0.000000000   0.000000000
#
# occupation.14 occupation.15 occupation.16 occupation.17 occupation.18
#   0.000000000   0.000000000   0.000000000   0.000000000   0.000000000
#
# occupation.19 occupation.20
#   0.000000000   0.000000000

unique_occupation[1]
[1] 'technician'
unique_occupation[8]
[1] 'educator'
unique_occupation[11]
[1] 'programmer'

# Plot the predicted probability densities separated by label values.
qplot(predicted_values, fill=factor(label_test),
                xlab='Predicted label probability', ylab='Density',
                alpha=I(0.5), geom='Density') +
        opts(legend.position='none')

# Plot the precision-recall curve.
pred = prediction(predicted_values, label_test)
perf = performance(pred, 'prec', 'rec')
plot(perf, col='red', xlim=c(0,1), ylim=c(0,1),
        main='Precision-recall', pch=26, lwd=5, cex=10.8)

# Plot the ROC curve.
perf = performance(pred, 'tpr', 'fpr')
plot(perf, col='red', xlim=c(0,1), ylim=c(0,1),
        main='ROC--AUC', pch=26, lwd=5, cex=10.8)

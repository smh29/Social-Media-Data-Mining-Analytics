library(lda)
library(ggplot2)

# Load the data.
data(poliblog.documents)
data(poliblog.vocab)
data(poliblog.ratings)     # It is important--we also have ratings per document.

?poliblog.documents

table(poliblog.ratings)
poliblog.ratings
-100  100
 464  309

num.topics = 10

# Initialize the parameters.
params = sample(c(-1, 1), num.topics, replace=TRUE)

result = slda.em(documents=poliblog.documents,
        K=num.topics,
        vocab=poliblog.vocab,
        num.e.iterations=10,
        num.m.iterations=4,
        alpha=1.0,
        eta=0.1,
        poliblog.ratings / 100,
        params,
        variance=0.25,
        lambda=1.0,
        logistic=FALSE,
        method='sLDA')

# Pick the top words for each topic.
topics = apply(top.topic.words(result$topics, 5, by.score=TRUE), 2,
        paste, collapse=' ')

topics
 [1] "wright hes people said just"
 [2] "tax money oil new make"
 [3] "mccain said president john mccains"
 [4] "clinton obama voters vote percent"
 [5] "obama barack hillary obamas clinton"
 [6] "democratic race election party primary"
 [7] "senator like media dont debate"
 [8] "war house iraq bush law"
 [9] "government just people political federal"
[10] "senate district republican candidates house"

# Get the coefficients for the regresssion.
coefs = data.frame(coef(summary(result$model)))
coefs = cbind(coefs, Topics=factor(topics, topics[order(coefs$Estimate)]))
coefs = coefs[order(coefs$Estimate),]

qplot(Topics, Estimate, colour=Estimate, size=abs(t.value), data=coefs) +
        geom_errorbar(width=0.5,
                aes(ymin=Estimate - Std..Error, ymax=Estimate+Std..Error)) +
        coord_flip()

predictions = slda.predict(poliblog.documents,
        result$topics,
        result$model,
        alpha=1.0,
        eta=0.1)

qplot(predictions,
                fill=factor(poliblog.ratings),
                xlab='predicted rating',
                ylab='density',
                alpha=I(0.5),
                geom='density') +
        geom_vline(aes(xintercept=0)) +
        theme(legend.position='none')

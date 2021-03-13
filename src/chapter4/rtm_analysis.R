library(lda)
library(ggplot2)

# Load the data.
data(cora.documents)
data(cora.vocab)
data(cora.titles)
data(cora.cites)              # Now we also have citations.

# Inspect the data and seeing the explanations.
?cora.documents
head(cora.documents)
length(cora.documents)
head(cora.vocab)
length(cora.vocab)

# The number of topics.
K = 10

# Fit an RTM model.
rtm.model = rtm.collapsed.gibbs.sampler(cora.documents,
        cora.cites,           # Links are input to the model.
        K,
        cora.vocab,
        35,
        0.1, 0.1, 6)

# Fit an LDA model to the topics.
lda.model = lda.collapsed.gibbs.sampler(cora.documents,
        K,                    # The Number of topics.
        cora.vocab,
        50,                   # The number of iterations.
        0.1,
        0.1,
        compute.log.likelihood=TRUE)

top.words.rtm = top.topic.words(rtm.model$topics, 5, by.score=TRUE)
top.words.lda = top.topic.words(lda.model$topics, 5, by.score=TRUE)

top.words.rtm
     [,1]       [,2]           [,3]         [,4]        [,5]         [,6]
[1,] "learning" "genetic"      "bayesian"   "decision"  "research"   "markov"
[2,] "networks" "optimization" "data"       "tree"      "grant"      "chain"
[3,] "training" "control"      "belief"     "trees"     "university" "sampling"
[4,] "network"  "neural"       "model"      "crossover" "science"    "distribution"
[5,] "features" "design"       "regression" "examples"  "supported"  "error"
     [,7]        [,8]            [,9]        [,10]
[1,] "network"   "reinforcement" "algorithm" "knowledge"
[2,] "neural"    "genetic"       "queries"   "design"
[3,] "networks"  "algorithm"     "time"      "reasoning"
[4,] "visual"    "fitness"       "learner"   "system"
[5,] "recurrent" "population"    "query"     "planning"

top.words.lda
     [,1]        [,2]      [,3]          [,4]             [,5]        [,6]
[1,] "neural"    "visual"  "logic"       "theory"         "knowledge" "bayesian"
[2,] "networks"  "network" "instruction" "error"          "learning"  "models"
[3,] "network"   "model"   "clauses"     "generalization" "system"    "model"
[4,] "learning"  "neural"  "processor"   "belief"         "reasoning" "data"
[5,] "recurrent" "system"  "programming" "learning"       "planning"  "networks"
     [,7]        [,8]           [,9]         [,10]
[1,] "search"    "genetic"      "algorithm"  "research"
[2,] "algorithm" "evolutionary" "algorithms" "grant"
[3,] "decision"  "programming"  "bayesian"   "university"
[4,] "trees"     "fitness"      "decision"   "science"
[5,] "genetic"   "population"   "data"       "report"


##############################################################################
# Listing 4.16                                                               #                             
# Comparing LDA and RTM with link prediction.                                #
##############################################################################

# Randomly sample 100 edges.
edges = links.as.edgelist(cora.cites)

# Sample the edges and find the probabilities.
sampled.edges = edges[sample(dim(edges)[1], 100),]
rtm.similarity = predictive.link.probability(sampled.edges,
        rtm.model$document_sums, 0.1, 6)
lda.similarity = predictive.link.probability(sampled.edges,
        lda.model$document_sums, 0.1, 6)

# Compute how many times each document was cited.
cite.counts = table(factor(edges[, 1],
                levels=1 : dim(rtm.model$document_sums)[2]))

# Which topic is most expressed by the cited document.
max.topic = apply(rtm.model$document_sums, 2, which.max)

qplot(lda.similarity, rtm.similarity,
                size=log(cite.counts[sampled.edges[, 1]]),
                colour=factor(max.topic[sampled.edges[, 2]]),
                xlab='LDA predicted link probability',
                ylab='RTM predicted link probability',
                xlim=c(0, 0.5), ylim=c(0, 0.5)) +
        scale_size(name='log(Number of citations)') +
        scale_colour_hue(name='Max RTM topic of citing document')

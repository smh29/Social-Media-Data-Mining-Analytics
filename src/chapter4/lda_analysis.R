library(lda)
library(reshape2)
library(ggplot2)

# Load the Cora data set.
data(cora.documents)
data(cora.vocab)
data(cora.titles)

# Inspect data, seeing explanation, top rows and length.
?cora.documents
head(cora.documents)
length(cora.documents)
head(cora.vocab)
length(cora.vocab)

# The number of topics.
K = 10

# Setting the random seed for reproducibility.
set.seed(867101)

# Model fitting with the Gibbs sampler. It only takes the document-term matrix
# (with vocabulary).
result = lda.collapsed.gibbs.sampler(cora.documents,
        K,                        # The number of topics.
        cora.vocab,
        50,                       # The number of iterations.
        0.1,                      # Parameters.
        0.1,
        compute.log.likelihood=TRUE)

# Get the top words in the cluster. Top words are the characteristics of the
# relevant topic.
top.words = top.topic.words(result$topics, 5, by.score=TRUE)

top.words
     [,1]          [,2]        [,3]       [,4]        [,5]           
[1,] "genetic"     "functions" "bayesian" "learning"  "reinforcement"
[2,] "programming" "parallel"  "models"   "decision"  "learning"     
[3,] "robot"       "function"  "data"     "inductive" "algorithm"    
[4,] "system"      "neural"    "markov"   "induction" "methods"      
[5,] "crossover"   "control"   "model"    "concept"   "state"        
     [,6]             [,7]        [,8]       [,9]           [,10]       
[1,] "algorithm"      "reasoning" "network"  "genetic"      "research"  
[2,] "learning"       "knowledge" "neural"   "search"       "grant"     
[3,] "error"          "design"    "networks" "fitness"      "university"
[4,] "bounds"         "case"      "input"    "optimization" "report"    
[5,] "classification" "system"    "training" "selection"    "technical" 

# Number of documents to display.
N = 10

# This is a normalization for assignments in the Gibbs sampling.
topic.proportions = t(result$document_sums) / colSums(result$document_sums)

# Take 10 random samples.
index = sample(1 : dim(topic.proportions)[1], N)
topic.proportions =  topic.proportions[index,]

# There might be empty documents.
topic.proportions[is.na(topic.proportions)] =  1 / K

colnames(topic.proportions) = apply(top.words, 2, paste, collapse=" ")

# Prepare the data for ggplot.
topic.proportions.df =
        melt(cbind(data.frame(topic.proportions), document=factor(1 : N)),
        variable.name="topic",
        id.vars="document")

ggplot(data=topic.proportions.df, aes(x=topic, y=value)) +
        geom_bar(stat='identity') +
        coord_flip() + facet_wrap(~ document, ncol=5) +
        theme(axis.text.x=element_text(angle=90, hjust=1))

cora.titles[index]
 [1] "Using dirichlet mixture priors to derive hidden Markov models for protein families."
 [2] "Incremental self-improvement for lifetime multi-agent reinforcement learning."
 [3] "Stochastic pro-positionalization of non-determinate background knowledge."
 [4] "Linden (1998). Model selection using measure functions."
 [5] "On the informativeness of the DNA promoter sequences domain theory."
 [6] "(in preparation) \"Between MDPs and semi-MDPs: learning, planning, and representing knowledge at multiple temporal scales.\""
 [7] "\"Gambling in a rigged casino: the adversarial multi-armed bandit problem,\""
 [8] "The Pandemonium system of reflective agents."
 [9] "\"The weighted majority algorithm\","
[10] "\"The Complexity of Real-time Search.\""

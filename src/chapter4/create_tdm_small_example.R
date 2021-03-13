library(lda)
library(tm)

documents = c(
        'I love football and Messi is my favorite player',
        'The demonstration on the football field was spectacular',
        'This is just a demonstration for the LDA package'
)

corpus = lexicalize(documents)

# Use the stop words list from the `tm` package.
stop.words = stopwords('en')

# Get the list of words. This is a function in LDA package.
words = word.counts(corpus$documents)

# Specify which words in the vocabulary are stop words.
words.to.be.removed = as.numeric(names(words)[corpus$vocab %in% stop.words])

# Filter out those words from the corpus.
docs.filtered = filter.words(corpus$documents, words.to.be.removed)

corpus$vocab
 [1] "i"             "love"          "football"      "and"          
 [5] "messi"         "is"            "my"            "favorite"     
 [9] "player"        "the"           "demonstration" "on"           
[13] "field"         "was"           "spectacular"   "this"         
[17] "just"          "a"             "for"           "lda"          
[21] "package"

docs.filtered
[[1]]
     [,1] [,2] [,3] [,4] [,5]
[1,]    1    2    4    7    8
[2,]    1    1    1    1    1

[[2]]
     [,1] [,2] [,3] [,4]
[1,]   10    2   12   14
[2,]    1    1    1    1

[[3]]
     [,1] [,2] [,3] [,4]
[1,]   16   10   19   20
[2,]    1    1    1    1

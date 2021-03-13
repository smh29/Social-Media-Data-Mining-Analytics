# This code snippet has been originated from COS424 Course
# at Princeton University by Prof. David Blei and modified accordingly to
# follow the story in this chapter.

library(Matrix)
library(NMF)
library(ggplot2)

# Reads data, fits the model, and saves it.
how.i.fit.the.model = function()
{
    # Data is stored in data/movielens/ml-100k/u.mm file given with the source code. 
    x = readMM('data/movielens/ml-100k/u.mm')
    s = as.matrix(x)

    # We know that the number of users is 938.
    number.of.users = 938

    # Get the relevant users only we are interested in. 
    s = s[1 : number.of.users,]

    # K, the rank, is set to 20.
    K = 20

    # The model is trained here.
    # This is the factorization stage. It takes some time.
    # There are several methods/algorithms incorporating different
    # regularization techniques. Run help(n/f) in R to see further details.
    # Here we use the default one incorporating a KL divergence-based
    # cost function.
    my.nmf.20 = nmf(s, K, .options='v')

    # Save the model to disk to be used later. We want to save it to the disk
    # since it is expensive to re-run it again and again.
    save(my.nmf.20, file='data/movielens/fits/nmf20.rda')
}

how.i.fit.the.model()

load('data/movielens/fits/nmf20.rda')

# Give the object a convenient name.
# We will use it later in the following code sections.
m = my.nmf.20

# Look at the structure of the result
str(m)

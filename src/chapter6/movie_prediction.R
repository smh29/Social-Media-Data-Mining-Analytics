# Generate an empty user
me = numeric(1682)

# The movies 195 and 96 are the items including the search string "Terminator"
grep('Terminator', items$title)
195 96

# Here we give the highest possible rating of 5 to movies relevant to
# "Terminator".
# This is just for experimental purposes in this example. One can rate any
# other movie this way with different ratings.
me[195] = 5
me[96] = 5

# Get the factor scores of the user. m is a NMFfit data structure we
# calculated earlier. To reach sub components we need to use @ symbol.
# We find the factor scores for the user rated Terminators with 5 stars. 
# This is the mapping stage. fit@H corresponds to matrix D in our notation
# in the book.
# my.factors corresponds to s_i in our notation.
my.factors = me %*% t(m@fit@H)

# Plot the factors according to the stereotypes.
barplot(my.factors)

# With the given factor score, we estimate the entire item scores for the user.
# This is the inverse transform stage. We map back to the movie space.
my.prediction = my.factors %*% m@fit@H

# Order the predictions and get the top 10.
items$title[order(my.prediction, decreasing=T)[1 : 10]]

[1] "Raiders of the Lost Ark (1981)"  "Empire Strikes Back, The (1980)"
[3] "Star Wars (1977)"                "Terminator 2: Judgment Day (1991)"
[5] "Fugitive, The (1993)"            "Terminator, The (1984)"
[7] "Braveheart (1995)"               "Return of the Jedi (1983)"
[9] "Pulp Fiction (1994)"             "Indiana Jones and the Last Crusade (1989)"

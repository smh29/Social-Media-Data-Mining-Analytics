# ----- helper functions

# Print the top 10 movies with names according to what weight they get.
print.top.movies = function(k, fit, items, n=10)
{
    cat((items$title[order(fit@H[k,], decreasing=T)[1 : n]]), sep='\n')
}

# Plot the genre distribution from the downloaded data for a given stereotype.
plot.top.genres = function(k, fit, items, n=10)
{
    # In the items data the genres are given in the indexes from 6 : 24.
    # The schema of this is:
    # "id", "title", "date", "video", "imdb",
    # "unknown", "action", "adventure", "animation", "childrens",
    # "comedy", "crime", "documentary", "drama", "fantasy", "film-noir",
    # "horror", "musical", "mystery", "romance", "scifi", "thriller", "war",
    # "western"
    barplot(colSums(items[order(fit@H[k,], decreasing=T)[1 : n], 6 : 24]),
            las=2)
}

# a helper function highly voting movies including specific keywords 
# and giving recommendations based on that.
rec.movies = function(title, fit, items, n=10)
{
    #we know that the number of items is 1682
    number.of.items = 1682
    
    #create an empty new user.	
    me = numeric(number.of.items)
    
    #give a 5 rating to movies with the title given. Fore example if the user is 
    #interested in Terminator, this movie is rated as 5.
    me[grep(title, items$title)] = 5
    
    #get the factor scores of the user. The $m$ is a NMFfit data structure produced
    #by nmf package. To reach sub components we need to use @ symbol.
    #with movie given in the title rated 5, we find the factor scores for the
    #hypothethical user here. This is the mapping stage. 
    #fit@H is the \textbf{D} in our notation above. It comes as an argument to the function
    #my.factors is the \textbf{s}_i in our notation.
    my.factors = me %*%  t(fit@H)
    
    #with the given factor score, we estimate the entire item scores for the user.
    #this is the inverse transform stage. We map back to the movie space.
    my.prediction = my.factors %*% fit@H
    
    #we sort the predictions and return top n as recommendations.
    items$title[order(my.prediction, decreasing=T)[1:n]]
}


# the covariate information for the movies are stored in a sperate file.
# here we read those and set up column names next.
items = read.table("data/movielens/ml-100k/u.item", sep="|", quote="", as.is=T)

#below we set the schema of the data. We will explain each:
#id: the unique id of the movie
#title: a string representing the title
#date: date of the movie.
#video: link if there exists a video online. NA otherwise.
#imdb: link to the imdb page.
#rest of the columns are binary values from "unknown" to "western"
#if the movie is in that genre the value is 1, otherwise it is 0. 
colnames(items) = c("id", "title", "date", "video", "imdb", "unknown",
        "action", "adventure", "animation", "childrens",
        "comedy", "crime", "documentary", "drama", "fantasy",
        "film-noir","horror", "musical", "mystery", "romance",
        "scifi", "thriller", "war", "western")

#here we get the user information.
#below we set the schema of the data. We will explain each:
#id: the unique id of the user
#age: age of the user
#gender: gender of the user
#occupation: what is the occupation of the user?
#zip code: location of the user
users = read.table("data/movielens/ml-100k/u.user", sep="|", quote="", as.is=T)

#we know that the number of users is 938.
number.of.users = 938
users = users[1:number.of.users,]

#give the schema a human readable format.
colnames(users) = c("id", "age", "gender", "occupation", "zip code")

#here is the five users with their covariates.
head(users)
id age gender occupation zip code
1  1  24      M technician    85711
2  2  53      F      other    94043
3  3  23      M     writer    32067
4  4  24      M technician    43537
5  5  33      F      other    15213
6  6  42      M  executive    98101


#printing the characteristics of the stereotype movies. e.g. 5.
#here we plots stats for the 5th stereotype. It could be anything from
#1-20. Below we show 4 samples plotted. Feel free to try other values.                      
print.top.movies(5, m@fit, items)
get.top.genres(5, m@fit, items)

#here we plot the covariate information vs the factor scores of the 
#users corresponding to the covariates.
qplot(users$gender, m@fit@W[,5],ylim=c(0,100))
qplot(users$age, m@fit@W[,5],ylim=c(0,100))
qplot(users$occupation, m@fit@W[,5],ylim=c(0,100))

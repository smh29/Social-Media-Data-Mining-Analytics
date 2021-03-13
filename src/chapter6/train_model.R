library(glmnet)
library(Matrix)
library(ROCR)
library(ggplot2)

# Read the feature data. The schema is explained below.
users = read.table('data/movielens/ml-100k/u.user', sep='|', quote='', as.is=T)

# The number of users we consider is 938.
number.of.users = 938
users = users[1 : number.of.users,]

# Give the schema human-readable column names.
colnames(users) = c('id', 'age', 'gender', 'occupation', 'zip code')

# The first six users with their covariates. 
head(users)

#   id age gender occupation zip code
# 1  1  24      M technician    85711
# 2  2  53      F      other    94043
# 3  3  23      M     writer    32067
# 4  4  24      M technician    43537
# 5  5  33      F      other    15213
# 6  6  42      M  executive    98101

# The data is stored in the ml-100k/u.mm file given with the source code. 
# the rows represent users, the columns represents movies. If a user
# did not watch a movie, its rating is 0, otherwise the rating is the integer
# value between 1 and 5.
x = readMM('ml-100k/u.mm')
s = as.matrix(x)

# Get the relevant users only we are interested in. 
s = s[1 : number.of.users,]

# Load the movie data.
items = read.table('data/movielens/ml-100k/u.item', sep='|', quote='', as.is=T)
colnames(items) = c('id', 'title', 'date', 'video', 'imdb', 'unknown',
        'action', 'adventure', 'animation', 'childrens',
        'comedy', 'crime', 'documentary', 'drama', 'fantasy',
        'film-noir','horror', 'musical', 'mystery', 'romance',
        'scifi', 'thriller', 'war', 'western')

# The following returns which movies are related to the "Terminator".
grep('Terminator', items$title)

# 195 96

labels = rep(0, number.of.users)
# Set the labels. We want to predict which users would likely watch
# the "Terminator" with a rating of at least 4.
labels[which(s[, 96] > 3 | s[, 195] > 3)] = 1

# There are three groups of features: 1) age, 2) gender 3) occupation
# age does not require any modification or transformation
age_feature = users$age

# Gender features should be encoded to binary. 0 = male, 1 = female
gender_feature = rep(0, number.of.users)
gender_feature[users$gender=='F'] = 1

# Occupation features should be binary as well.
# Each occupation we encode as a separate feature.
unique_occupation = unique(users$occupation)
occupation_features = matrix(0, number.of.users, length(unique_occupation))
for(i in 1 : length(unique_occupation)) {
    occupation_features[users$occupation == unique_occupation[i], i] = 1
}

data = data.frame(label=labels, age=age_feature, gender=gender_feature,
        occupation=occupation_features)

#number of features
n_feature = dim(data)[2]-1

##parameters
#What portion of the data will be held-out for prediction purposes.
train_test_ratio = 0.4
#Which column will be used as the response variable
problem = 1


##divide the data into 2 pieces: (1)Training, (2)Testing--we want to measure how well we are doing!
nsample = dim(data)[1]
ntest = round(train_test_ratio*nsample)
test_index = sample(1:nsample,ntest)
train_index = rep(1,nsample)==1
train_index[test_index] = FALSE
data_test = data[test_index,]
data_train = data[which(train_index),]


##normalization
features_train= as.matrix(data_train[,2:n_feature])
label_train = as.matrix(as.numeric(data_train[,problem]))

##take the mean and variance of the feature.
mean_tr = apply(features_train,2,mean)
std_tr = apply(features_train,2,sd)
features_train = apply(features_train,2,function(x) x-mean(x))
features_train = apply(features_train,2,function(x) x/sd(x))

features_test= as.matrix(data_test[,2:n_feature])
label_test = as.matrix(as.numeric(data_test[,problem]))

#normalizing features for held-out data. Pay attention to the fact that
# use the mean and standard deviation estimated using the training set. 
# During model training we can only use the training data, meaning that
# even feature transformation can only use training data. During held-out prediction
# we can use whatever we learned from training set, including the mean and sd.
M = dim(features_test)[2]
N = dim(features_test)[1]
features_test = features_test - t(matrix(rep(mean_tr,N),M,N))
features_test = features_test / t(matrix(rep(std_tr,N),M,N))

# Here we fit the model. We provide features and labels.
# family=binomial means that this is a classification problem. 
fit = glmnet(as.matrix(features_train), as.matrix(label_train),
        family='binomial', alpha=1)

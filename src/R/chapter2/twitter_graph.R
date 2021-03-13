library(ggplot2)

source('src/R/default.R')

##############################################################################
# The density plots of follower & followee counts on Twitter.                #
##############################################################################

library(rPython)

python.load('src/chapter2/twitter_followers_and_followees.py')
ff = python.call('followers_followees_stat')
followers = data.frame(bucket=ff[[1]], count=ff[[2]] / sum(ff[[2]]), type='Followers')
followees = data.frame(bucket=ff[[3]], count=ff[[4]] / sum(ff[[4]]), type='Followees')

ggplot(rbind(followers, followees), aes(x=bucket, y=count)) +
  geom_line(aes(group=type), size=defaults$line.size, alpha=0.5) +
  geom_point(data=rbind(
      data.frame(create.log.line.markers(followers, 15), type='Followers'),
      data.frame(create.log.line.markers(followees, 22), type='Followees')),
    aes(x=x, y=y, shape=type), size=defaults$point.size, fill='white') +
  scale_shape_manual(name='', values=21 : 22) +
  scale_x_log10('Number of followers / followees', limits=c(1, 1e4),
    breaks=trans_breaks('log10', function(x) 10^x),
    labels=trans_format('log10', math_format(10 ^ .x))) +
  scale_y_log10('Density',
    breaks=trans_breaks('log10', function(x) 10^x),
    labels=trans_format('log10', math_format(10 ^ .x)))

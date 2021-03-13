library(plyr)
library(ggplot2)
library(reshape2)
library(scales)

source('src/R/default.R')

##############################################################################
# Listing 1.2                                                                #
# Plot the histogram of user edits in the first period                       #
##############################################################################

revs.in.periods = read.table(
  gzfile('data/wikipedia/user_edits_in_timeframes.tsv.gz'),
  sep='\t', col.names=c('account', 'range1', 'range2', 'range3'),
  comment.char='', quote='')

# Only users with > 0 edits in Jan 2013 are considered.
ggplot(subset(revs.in.periods, range1 > 0, select='range1'), aes(range1)) +
  geom_histogram(binwidth=1, origin=-0.5) + xlim(0, 20) +
  xlab('Number of revisions made') + ylab('Number of users in period')


##############################################################################
# Figure 1.3 / Listing 1.3                                                   #
# Plot the histograms of user edit frequencies for all three periods         #
##############################################################################

# Transform revs.in.periods from a wide format to long format for plotting
revs.in.periods.long = melt(revs.in.periods, 'account',
  variable.name='range', value.name='revisions')
# Keep only users who made at least one edit in a given period
revision.counts = ddply(subset(revs.in.periods.long, revisions > 0),
  .(range, revisions), nrow)
ggplot(revision.counts, aes(x=revisions, y=V1)) +
  geom_line(aes(group=range),
    size=defaults$line.size, alpha=0.5) +
  geom_point(aes(shape=range),
    size=defaults$point.size, fill='white') +
  xlim(1, 20) +
  xlab('Number of revisions made') +
  ylab('Number of users in period') +
  scale_shape_manual(name='Period',
    breaks=c('range1', 'range2', 'range3'),
    labels=c('Jan', 'Jan-Feb', 'Jan-Mar'),
    values=21 : 23)


##############################################################################
# Figure 1.4                                                                 #
# Plot the PDFs of user edit frequencies for all three periods               #
##############################################################################

# Calculate the fraction of users separately for each date range who
# make a certain number of revisions, excluding all users who make zero edits
# in any of the time windows
normalized.revisions = ddply(subset(revs.in.periods.long, revisions > 0),
  .(range), function(one.range) {
    user.count = nrow(one.range)
    print(user.count)
    ddply(one.range, .(revisions),
      function(one.revision)
        data.frame(user.fraction=nrow(one.revision) / user.count)
    )
  })

ggplot(normalized.revisions, aes(x=revisions, y=user.fraction, group=range)) +
  geom_line(size=defaults$line.size, alpha=0.5) +
  geom_point(aes(shape=range), size=defaults$point.size, fill='white') +
  xlim(1, 20) +
  xlab('Number of revisions made') +
  ylab('Fraction of users in period') +
  scale_shape_manual(name='Period',
    breaks=c('range1', 'range2', 'range3'),
    labels=c('Jan', 'Jan-Feb', 'Jan-Mar'),
    values=21 : 23)


##############################################################################
# Determine the RMS errors of the PDF values from their means                #
##############################################################################

normalized.revisions.long = dcast(normalized.revisions, revisions ~ range,
  value.var='user.fraction')
normalized.revisions.long$mean = rowMeans(
  normalized.revisions.long[, c('range1', 'range2', 'range3')])
x = normalized.revisions.long[which(!is.na(normalized.revisions.long$mean)),
  2 : 5]
x = x[1 : 100,]

# The RMS errors of the first 100 data points of the three curves
# around their averages
sqrt(sum(((x$mean - x$range1) / x$mean) ^ 2) / length(x$mean))
sqrt(sum(((x$mean - x$range2) / x$mean) ^ 2) / length(x$mean))
sqrt(sum(((x$mean - x$range3) / x$mean) ^ 2) / length(x$mean))


##############################################################################
# Figure 1.5 / Listing 1.4                                                   #
# Take the ratios at every points of the histograms                          #
##############################################################################

# Count the number of users in each period with a given number of > 0 revisions
user.counts.long = ddply(subset(revs.in.periods.long, revisions > 0),
  .(range, revisions), nrow)
# Reformat the results into a wide table where the number of revisions are
# the rows and in three columns we have the user counts for each of the ranges
user.counts.wide = dcast(user.counts, revisions ~ range)
# Calculate the pairwise ratios between the user frequencies in each
# revision bucket, with respect to those in range 1
ratios = within(user.counts.wide, {
    ratio21 = range2 / range1
    ratio31 = range3 / range1
  })
# Make long table again for plotting
ratios = melt(ratios[, c('revisions', 'ratio21', 'ratio31')],
  id.vars='revisions', variable.name='period.ratio', value.name='ratio')
ggplot(ratios, aes(x=revisions, y=ratio)) +
  geom_line(aes(roup=period.ratio, alpha=period.ratio), size=defaults$line.size) +
  xlim(1, 50) + ylim(1, 3) +
  xlab('Number of revisions made') +
  ylab('Ratio of the number of users') +
  scale_alpha_manual(name='Ratio to Period 1',
    breaks=c('ratio21', 'ratio31'),
    labels=c('Of Period 2', 'Of Period 3'),
    values=c(1, 0.3))


##############################################################################
# Figure 1.6                                                                 #
# The difference between the revision counts in periods 2 & 3, with respect  #
# to period 1                                                                #
##############################################################################

actives.in.2 = subset(revs.in.periods, range2 > 0)
actives.in.2 = ddply(actives.in.2, .(range1), summarise,
  mean2=mean(range2), mean3=mean(range3))
actives.in.2 = subset(actives.in.2, range1 <= 100)
actives.in.2 = melt(actives.in.2, id.vars='range1')
ggplot(actives.in.2, aes(x=range1, y=value, group=variable)) +
  geom_point(aes(shape=variable), size=defaults$point.size / 2) +
  geom_smooth(method='lm', se=FALSE,
    size=defaults$line.size, color=alpha('black', 0.5)) +
  xlab('Revisions in Period 1') +
  ylab('Average edits in Period 2 & 3') +
  ylim(0, 300) +
  scale_shape_manual(name='Average edits',
    breaks=c('mean2', 'mean3'),
    labels=c('In Period 2', 'In Period 3'),
    values=c(0, 19))

# The linear fits
lm(value ~ range1, subset(actives.in.2, variable == 'mean2'))
lm(value ~ range1, subset(actives.in.2, variable == 'mean3'))


##############################################################################
# Figure 1.7                                                                 #
# User activity distributions on a log-log plot                              #
##############################################################################

revisions.bucket.counts = ddply(subset(revs.in.periods.long, revisions > 0),
  .(range, revisions), summarise, count=length(revisions))
ggplot(revisions.bucket.counts, aes(x=revisions, y=count)) +
  geom_line(aes(group=range), size=defaults$line.size / 3, alpha=0.5) +
  geom_point(aes(shape=range),
    size=defaults$point.size / 1.5, fill='white') +
  scale_shape_manual(name='Period',
    breaks=c('range1', 'range2', 'range3'),
    labels=c('Jan', 'Jan-Feb', 'Jan-Mar'),
    values=21 : 23) +
  scale_x_log10('Number of revisions made', limits=c(1, 1e4),
    breaks=trans_breaks('log10', function(x) 10^x),
    labels=trans_format('log10', math_format(10 ^ .x))) +
  scale_y_log10('Number of users in period',
    breaks=trans_breaks('log10', function(x) 10^x),
    labels=trans_format('log10', math_format(10 ^ .x)))


##############################################################################
# Figure 1.8 / Listing 1.5                                                   #
# Cumulative activity distribution                                           #
##############################################################################

rev.buckets = ddply(subset(revs.in.periods, range1 > 0, select='range1'),
  .(range1), summarise, count=length(range1))
names(rev.buckets)[1] = 'revisions'
# Make sure we have an increasing ordering of the revision buckets
rev.buckets = rev.buckets[order(rev.buckets$revisions),]
total.users = sum(rev.buckets$count)
rev.buckets = within(rev.buckets, {
    cdf = cumsum(count) / total.users
  })
ggplot(rev.buckets, aes(x=revisions, y=cdf)) +
  geom_line(size=defaults$line.size) +
  scale_x_log10('Number of revisions made', limits=c(1, 1e4),
    breaks=trans_breaks('log10', function(x) 10^x),
    labels=trans_format('log10', math_format(10 ^ .x))) +
  scale_y_continuous('Fraction of users w/no more edits')


##############################################################################
# Figure 1.9                                                                 #
# Tail distribution of the activities                                        #
##############################################################################

rev.buckets = ddply(subset(revs.in.periods, range1 > 0, select='range1'),
  .(range1), summarise, count=length(range1))
names(rev.buckets)[1] = 'revisions'
# Make sure we have an increasing ordering of the revision buckets
rev.buckets = rev.buckets[order(rev.buckets$revisions),]
total.users = sum(rev.buckets$count)
rev.buckets = within(rev.buckets, {
    # We reverse the vector twice since 'cumsum' adds up
    # from the beginning, and discard the very first bucket since
    # the CCDF is defined as a strict "greater".
    # Finally, we append a 0.0 value for the last element since
    # there are no users with more than the maximum number of edits.
    ccdf = c(rev(cumsum(rev(tail(count, -1)))) / total.users, 0.0)
  })
ggplot(rev.buckets, aes(x=revisions, y=ccdf)) +
  geom_line(size=defaults$line.size) +
  scale_x_log10('Number of revisions made', limits=c(1, 1e4),
    breaks=trans_breaks('log10', function(x) 10^x),
    labels=trans_format('log10', math_format(10 ^ .x))) +
  scale_y_continuous('The edits/user tail distribution',
    limits=c(0, 0.65))


##############################################################################
# Figure 1.10                                                                #
# Tail distribution of the activities, double logarithmic scale              #
##############################################################################

ggplot(rev.buckets, aes(x=revisions, y=ccdf)) +
  geom_line(size=defaults$line.size) +
  scale_x_log10('Number of revisions made', limits=c(1, 1e4),
    breaks=trans_breaks('log10', function(x) 10^x),
    labels=trans_format('log10', math_format(10 ^ .x))) +
  scale_y_log10('The edits/user tail distribution',
    limits=c(1e-4, 1),
    breaks=trans_breaks('log10', function(x) 10^x),
    labels=trans_format('log10', math_format(10 ^ .x)))


##############################################################################
# Figure 1.11                                                                #
# Illustration for integral vs. discrete sum                                 #
##############################################################################

example.function = function(x) {
  return(1 / x)
}
discrete = data.frame(x=2 : 6)
discrete = within(discrete, { y = example.function(x) })
continuous = data.frame(x=seq(1, 8, by=0.01))
continuous = within(continuous, { y = example.function(x) })
ggplot() +
  geom_bar(data=discrete, aes(x=x + 0.5, y=y, width=1), stat='identity',
    fill='white', color='black', size=defaults$line.size / 2) +
  geom_line(data=continuous, aes(x=x, y=y), size=defaults$line.size) +
  geom_area(data=subset(continuous, x >= 2 & x <= 7), aes(x=x, y=y),
    alpha=0.2) +
  geom_point(data=discrete, aes(x=x, y=y), shape=21, size=defaults$point.size, fill='white') +
  scale_x_continuous('', breaks=2 : 7) +
  ylab('') +
  theme(axis.ticks = element_blank(), axis.text.y = element_blank())


##############################################################################
# Figure 1.12 / Listing 1.7                                                  #
# What percentage of the highest activity users is responsible for a         #
# certain fraction of edits?                                                 #
##############################################################################

range.considered = subset(revs.in.periods, range1 > 0, select='range1')
names(range.considered)[1] = 'revisions'
ordered.activities = range.considered[order(range.considered$revisions,
    decreasing=TRUE),]
total.revisions = sum(ordered.activities)
tail.fractions = data.frame(user.rank=(1 : length(ordered.activities)),
  fraction=cumsum(ordered.activities) / total.revisions)
ggplot(tail.fractions, aes(x=user.rank, y=fraction)) +
  geom_line(size=defaults$line.size) +
  scale_x_log10('Most active user rank',
    breaks=trans_breaks('log10', function(x) 10^x),
    labels=trans_format('log10', math_format(10 ^ .x))) +
  scale_y_continuous('Fraction of all edits up to this rank')


##############################################################################
# Table 1.1                                                                  #
# The most active Wikipedia users                                            #
##############################################################################

head(tail.fractions, 20)
tail.fractions[100,]
# Seconds between two edits for the top 12 accounts
(31 * 24 * 60 * 60) / head(ordered.activities, 12)

# The top users, showing also the account names
s = subset(revs.in.periods, range1 > 0)
head(s[order(s$range1, decreasing=TRUE),])


##############################################################################
# Listing 1.8                                                                #
# Run this optionally to remove bots                                         #
##############################################################################

bots = read.table(gzfile('data/wikipedia/wikipedia_robots.txt.gz'),
  col.names=c('account'), sep='\t', comment.char='', quote='')
revs.in.periods = revs.in.periods[!(revs.in.periods$account %in% bots$account), ]


##############################################################################
# Figure 1.13                                                                #
# The p/q fractions as a function of the \gamma parameter illustrated        #
# Run the code for Fig. 2.11 first to generate the tail fractions data       #
##############################################################################

gammas = c(-1.9, -1.94, -1.98)
data = data.frame()
for (gamma in gammas) {
  x = exp(seq(log(1), log(1e4), length.out=15))
  y = 1 - x ^ ((gamma + 2) / (gamma + 1))
  data = rbind(data, data.frame(x=x, y=y, gamma=gamma))
}
data$gamma = factor(data$gamma, ordered=TRUE)
ggplot(data, aes(x=x, y=y)) +
  geom_line(data=subset(tail.fractions, fraction <= 0.6),
    aes(x=user.rank, y=fraction),
    size=defaults$line.size, alpha=0.5) +
  geom_line(aes(group=gamma), size=defaults$line.size) +
  geom_point(aes(group=gamma, shape=gamma), size=defaults$point.size, fill='white') +
  scale_x_log10('Most active user rank',
    breaks=trans_breaks('log10', function(x) 10^x),
    labels=trans_format('log10', math_format(10 ^ .x))) +
  scale_y_continuous('Fraction of activities up to this rank') +
  scale_shape_manual(name='Exponent',
    breaks=gammas, labels=sprintf('%.2f', gammas), values=21 : 23)

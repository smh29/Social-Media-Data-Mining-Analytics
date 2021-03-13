source('src/R/default.R')

##############################################################################
# Figure 3.21                                                                #
# Some user and page edit counts in time                                     #
#                                                                            #
# Run "python src/chapter3/wikipedia_select_bursty_users.py" first to find   #
# the interedit times of users for one week.                                 #
##############################################################################

revisions = read.table(gzfile('data/wikipedia/revisions_only_for_one_week.tsv.gz'),
  sep='\t', col.names=c('user.id', 'page.id', 'timestamp'))
revisions$timestamp = as.POSIXct(strptime(revisions$timestamp, '%Y-%m-%dT%H:%M:%SZ'))

# Choose a random user who has done a relatively large number of edits so that
# we can see a good time series
user.edit.counts = ddply(revisions, .(user.id), summarize,
  total.edits=nrow(piece))
user.edit.counts = user.edit.counts[
  order(user.edit.counts$total.edits, decreasing=T),]
summary(user.edit.counts$total.edits)

# Bucketize a list of timestamps to get counts over time
calculate.time.buckets.for.timestamps = function(timestamps,
  period.begin, period.end, bucket.length.sec) {
  EPOCH = as.POSIXct('2012-01-01')
  
  seconds.since.epoch = function(time, epoch) {
    return(as.numeric(time - epoch, units='secs'))
  }
  
  time.buckets = seq(seconds.since.epoch(period.begin, EPOCH),
    seconds.since.epoch(period.end, EPOCH), by=bucket.length.sec)
  event.counts.in.buckets = ddply(data.frame(time.bucket=
        time.buckets[cut(seconds.since.epoch(timestamps, EPOCH), time.buckets,
            include.lowest=T, right=F, labels=F)]),
    .(time.bucket), summarise, count=nrow(piece))
  
  # Add 0 values to every time bucket where the user was not active
  event.counts.in.buckets = merge(event.counts.in.buckets,
    data.frame(time.bucket=time.buckets), all.y=T)
  event.counts.in.buckets[is.na(event.counts.in.buckets$count),]$count = 0
  event.counts.in.buckets$time.bucket = EPOCH + event.counts.in.buckets$time.bucket
  return(event.counts.in.buckets)
}

# Faceted plot for a few sample user revision counts per hour
plot.time.series.for.users = function(revisions, selected.user.ids) {
  user.revisions = subset(revisions, user.id %in% selected.user.ids)
  
  epoch = as.POSIXct('2012-01-01')
  
  seconds.since.epoch = function(time, epoch) {
    return(as.numeric(time - epoch, units='secs'))
  }
  
  time.buckets = seq(seconds.since.epoch(as.POSIXct('2013-01-01'), epoch),
    seconds.since.epoch(as.POSIXct('2013-01-08'), epoch), length.out=3600)
  all.user.events = ddply(user.revisions, .(user.id), function(df) {
      return(calculate.time.buckets.for.timestamps(df$timestamp,
          as.POSIXct('2013-01-01'), as.POSIXct('2013-01-08'), 200))
    })
  facet.labels = c('User A', 'User B', 'User C', 'User D')
  unique.user.ids = unique(all.user.events$user.id)
  all.user.events$label = with(all.user.events, facet.labels[match(user.id,
        unique.user.ids)])
  ggplot(all.user.events) +
    geom_line(aes(x=time.bucket, y=count)) +
    scale_x_datetime(labels=date_format('%m/%d'),
      breaks=date_breaks('2 day'), minor_breaks=date_breaks('1 day')) +
    labs(x='Date', y='Revisions / hour') +
    facet_wrap(~ label, ncol=2, scales='free') +
    theme(strip.background=element_rect(size=8)) +  # make the strip thicker
    theme(panel.margin=unit(2, 'lines'))
}

selected.user.ids = with(user.edit.counts,
  user.edit.counts[sample(which(total.edits > 2000 & total.edits < 2500), 4),]$user.id)
selected.user.ids = c(16266655, 2308770, 23407, 8024439)  # the plot was generated with these
plot.time.series.for.users(revisions, selected.user.ids)


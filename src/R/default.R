##############################################################################
# Some useful global definitions and helpers                                 #
##############################################################################

library(plyr)
library(ggplot2)
library(reshape2)
library(scales)
library(grid)


##############################################################################
# ggplot definitions                                                         #
##############################################################################

theme_set(theme_bw(base_size=26))
theme_update(aspect.ratio=0.53)
theme_update(axis.title.x=element_text(vjust=-1.1))
theme_update(axis.title.y=element_text(vjust=0.2, angle=90))
theme_update(plot.margin=unit(c(0.2, 0.2, 0.4, 0.4), "in"))

defaults = list(
  line.size=3,
  point.size=6,
  hardcopy.size=list(width=900, height=500)
)


##############################################################################
# Create buckets with exponentially increasing sizes in such a way that      #
# there is at least one integer in any of them                               #
##############################################################################
exp.integer.buckets = function(data, bucket.count) {
  r = range(data)
  min.bucket = floor(r[1])
  max.bucket = floor(r[2] + 1.5)
  d = log(max.bucket / min.bucket) / bucket.count
  counts = 0
  bounds = c(min.bucket)
  x = log(min.bucket)
  while (counts < bucket.count) {
    x = x + d
    x.int = floor(exp(x))
    if (x.int > tail(bounds, 1)) {
      bounds = c(bounds, x.int)
    }
    counts = counts + 1
  }
  return(bounds)
}


##############################################################################
# Create x, y points to be overlaid on a log-log line                        #
##############################################################################
create.log.line.markers = function(data, num.markers, by=NULL) {
  create.one = function(data) {
    x = data[, 1]
    r = log(range(x[x > 0]))
    x = seq(r[1], r[2], length.out=num.markers)
    a = approx(log(data[, 1]), log(data[, 2]), x)
    return(data.frame(x=exp(a$x), y=exp(a$y)))
  }
  if (is.null(by))
    return(create.one(data))
  else
    ddply(data, by, function(df) {
        create.one(df)
      })
}

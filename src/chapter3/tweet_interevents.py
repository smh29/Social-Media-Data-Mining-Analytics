import itertools


def bucket(timestamps, bucket_size):
    '''A function to count items in intervals of size bucket_size.'''

    sortedTs = sorted(timestamps)

    def bucket_of(ts):
        return int(ts / bucket_size)

    bucket_count = dict((b, len(list(vs))) \
                        for (b, vs) in itertools.groupby(sortedTs, bucket_of))
    max_bucket = max(itertools.imap(bucket_of, timestamps))
    min_bucket = min(itertools.imap(bucket_of, timestamps))
    return map(lambda bucket: bucket_count.get(bucket, 0),
               range(min_bucket, max_bucket))

mentions_per_minute = bucket(lunch_timestamps, 60)



def make_diffs(items):
    '''A helper to make a stream of the differences in times of an iterator.'''

    prev = None
    for x in items:
        if prev:
            yield x - prev
        prev = x

diffs = list(make_diffs(lunch_timestamps))


def exp_ma(items, decay=0.95, init=0.0):
    '''Exponential moving average calculation.'''

    for x in items:
        init = decay * init + (1.0 - decay) * x
        yield init

moving_ave = list(exp_ma(diffs, 0.999))


##################################################################
# Generate inter-event times coming from a Poisson distrubution. #
##################################################################

import numpy as np

mean0 = mean(diffs)
# A constant to correct for the truncation, but keep the means the same.
correction_due_to_quatization = 1.22

memoryless = np.random.exponential(
    1.0 / (correction_due_to_quatization * mean0), len(diffs)).astype(int)
print mean0, mean(memoryless)


##############################################
# Autocorrelations of the inter-event times. #
##############################################

def autocor(data):
    centered = np.array(data) - (np.ones(len(data)) * mean(data))
    normed = np.divide(centered, np.std(centered))
    pos_and_neg = np.correlate(normed, normed, mode='full')
    # Normalize the window size.
    ones = np.ones(len(data))
    denom = np.correlate(ones, ones, mode='full')
    win_normed = np.divide(pos_and_neg, denom)
    # The autocorrelation is symmetric, return the right half, and only
    # the first half of overlaps (0.5 to 0.75) to make the plot more compact.
    return win_normed[win_normed.size / 2 : int(0.75 * win_normed.size)]

plot(autocor(mentions_per_minute))

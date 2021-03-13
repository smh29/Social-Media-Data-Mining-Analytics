'''
Calculate the degree-dependent assortativity in the LiveJournal social network.
'''

INPUT = 'data/livejournal/livejournal-links.txt.gz'
OUTPUT = 'data/livejournal/degree_correlations-log.tsv.gz'

import gzip
from collections import defaultdict
import math


class OnlineMeanVariance():
    '''Online mean and variance calculations.

    For the details see for instance
    https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Online_algorithm
    '''
    def __init__(self):
        self.mean = 0.0             # The running mean, make this a float.
        self.count = 0              # Number of items added so far.
        self._M2 = 0.0              # The sum of squares of differences from the
                                    # running mean, float.
    def add(self, x):
        '''Register a new item.'''
        if x > 0:
            self.count += 1                     # Increment the count.
            delta = x - self.mean               # Follow the calculations for the
            self.mean += delta / self.count     # online algorithm.
            self._M2 += delta * (x - self.mean)

    def variance(self):
        '''Calculate the unbiased sample variance.'''
        if self.count <= 1:
            return None
        else:
            return self._M2 / (self.count - 1)


# First pass: count the in- and out-degrees of every node.
outdegrees = defaultdict(int)       # The out-degree for every node.
indegrees = defaultdict(int)        # The in-degree for every node.
with gzip.open(INPUT) as f:
    for line in f:
        source, destination = map(int, line.rstrip().split('\t'))
        outdegrees[source] += 1
        indegrees[destination] += 1

# Second pass: calculate the means and variances of the neighbor degree
# distributions.
# stats is a dict of dicts, the first level is for the in- & out-degrees,
# the second level is for the degree of the node under consideration.
stats = defaultdict(lambda: defaultdict(OnlineMeanVariance))
with gzip.open(INPUT) as f:
    for line in f:
        source, destination = map(int, line.rstrip().split('\t'))

        # Update the statistics for the four in- and out-degree combinations,
        # and two end points.
        stats[('in', 'in')][indegrees[source]].add(indegrees[destination])
        stats[('in', 'out')][indegrees[source]].add(outdegrees[destination])
        stats[('out', 'in')][outdegrees[source]].add(indegrees[destination])
        stats[('out', 'out')][outdegrees[source]].add(outdegrees[destination])

        stats[('in', 'in')][indegrees[destination]].add(indegrees[source])
        stats[('in', 'out')][indegrees[destination]].add(outdegrees[source])
        stats[('out', 'in')][outdegrees[destination]].add(indegrees[source])
        stats[('out', 'out')][outdegrees[destination]].add(outdegrees[source])

# Write the results to a file.
with gzip.open(OUTPUT, 'w') as out:
    for direction, dir_stats in stats.iteritems():
        for deg, stat in dir_stats.iteritems():
            out.write('\t'.join(map(str, [direction[0], deg, direction[1],
                                          stat.mean, stat.variance()])) + '\n')

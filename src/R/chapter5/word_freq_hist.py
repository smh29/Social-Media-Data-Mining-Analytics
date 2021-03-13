import sys

from keyed_mapreduce import keyed_mapreduce


def mapfn(line):
    return [(word, 1) for word in line.split()]


def plus(key, values):
    yield (key, sum(values))


def get_count(word_count):
    yield (word_count[1], 1)


# Read the words from stdin
word_counts = keyed_mapreduce(sys.stdin, mapfn, plus)
# Calculate the histogram of word counts
histogram = keyed_mapreduce(word_counts, get_count, plus)

# Print the histogram in decreasing order of the frequencies
for (freq, count) in sorted(histogram, key=lambda x: x[1], reverse=True):
    print "%i\t%i" % (freq, count)

import sys

from keyed_mapreduce import keyed_mapreduce


def mapfn(line):
    '''Split up a line into words.'''
    return [(word, 1) for word in line.split()]


def plus(key, values):
    '''Add up the values for the given key.'''
    yield (key, sum(values))


for wordcount in keyed_mapreduce(sys.stdin, mapfn, plus):
    print wordcount

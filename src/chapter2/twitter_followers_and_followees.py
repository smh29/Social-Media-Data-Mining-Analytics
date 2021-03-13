'''
Python script to be called from R to create aggregate statistics from
a large file.
'''

from collections import defaultdict
import gzip

FILE = 'data/twitter/followers_followees.tsv.gz'

def followers_followees_stat():
    followers_stat = defaultdict(int)
    followees_stat = defaultdict(int)
    with gzip.open(FILE) as f:
        for line in f:
            followers, followees = map(int, line.split('\t'))
            followers_stat[followers] += 1
            followees_stat[followees] += 1
    # We can only return vectors to R, no data frames.
    return [followers_stat.keys(), followers_stat.values(),
            followees_stat.keys(), followees_stat.values()]

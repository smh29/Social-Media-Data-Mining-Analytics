'''
The conditional time differences between edits of any user.
'''

import sys, gzip, math, random
from collections import defaultdict
from datetime import datetime


INPUT_FILE = 'data/wikipedia/revisions_time_sorted.tsv.gz'
OUTPUT_FILE_PATTERN = 'data/wikipedia/interedit_times_pairs_sample_%s.tsv.gz'

NUMBER_OF_SAMPLES = 1e7

DATE_RANGE = ('2013-01-01T00:00:00Z', '2013-04-01T00:00:00Z')
DATE_RANGE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'


class ReservoirSample():
    def __init__(self, sample_count):
        self.items = []
        self.sample_count = sample_count
        self.index = 0

    def add_item(self, item):
        if self.index < self.sample_count:
            self.items.append(item)
        else:
            r = random.randint(0, self.index - 1)
            if r < self.sample_count:
                self.items[r] = item
        self.index += 1


class IntereventTimePairsSample():
    '''A class to print out the interarrival times so that we can run a
    correlation test on them.'''

    def __init__(self, number_of_samples):
        self.reservoir = ReservoirSample(number_of_samples)
        self.last_seen = dict()
        self.last_dt = dict()
        self.items_added = 0

    def add(self, key, time):
        if key in self.last_seen:
            last_time = self.last_seen[key]
            dt = int((time - last_time).total_seconds())
            if key in self.last_dt:
                last_dt = self.last_dt[key]
                self.reservoir.add_item((last_dt, dt))
                self.items_added += 1
                if self.items_added == 1e6:
                    print time
            self.last_dt[key] = dt
        self.last_seen[key] = time

    def write_results(self, outstream):
        for items in self.reservoir.items:
            outstream.write('\t'.join(map(str, items)) + '\n')


interevent_times = dict()
for entity in ['users', 'pages']:
    outstream = gzip.open(OUTPUT_FILE_PATTERN % entity, 'w')
    interevent_times[entity] = IntereventTimePairsSample(NUMBER_OF_SAMPLES)

input_file = gzip.open(INPUT_FILE, 'r')
for line in input_file:
    title, namespace, page_id, rev_id, timestamp, user_id, user_name, ip = \
        line[:-1].split('\t')
    if timestamp < DATE_RANGE[0]:
        continue
    if timestamp >= DATE_RANGE[1]:
        break
    if user_id != '' and user_id != '0':
        user_id = int(user_id)
        page_id = int(page_id)
        timestamp = datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%SZ')
        interevent_times['users'].add(user_id, timestamp)
        interevent_times['pages'].add(page_id, timestamp)
input_file.close()

for entity in ['users', 'pages']:
    with gzip.open(OUTPUT_FILE_PATTERN % entity, 'w') as outstream:
        interevent_times[entity].write_results(outstream)

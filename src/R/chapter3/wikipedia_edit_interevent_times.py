'''
Calculate the inter-edit times for both Wikipedia editors and pages.

We also account for the censored sampling here for the beginning and
end of the sampling period; however we do this to see very large
interevent times only for infrequent events. 
'''

import sys, gzip, math
from collections import defaultdict
from datetime import datetime


INPUT_FILE = 'data/wikipedia/revisions_time_sorted.tsv.gz'
OUTPUT_FILE_PATTERN = 'data/wikipedia/interedit_times_%s.tsv.gz'

DATE_RANGE = ('2013-01-01T00:00:00Z', '2013-04-01T00:00:00Z')
DATE_RANGE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'


class IntereventTimes():
    '''A class to keep track of interevent times between arrivals of
       certain events, such as for user edits and page changes.'''

    LOG_BUCKET = math.log10(1e4) / 50

    def __init__(self, sampling_begin_time, sampling_end_time):
        self.last_seen = dict()
        self.interevent_times = defaultdict(int)
        self.first_time_seen = defaultdict(int)
        self.last_time_seen = defaultdict(int)
        self.sampling_begin_time, self.sampling_end_time = \
        (sampling_begin_time, sampling_end_time)

    def discretize(self, value):
        if value == 0:
            return -1
        return int(math.log10(int(value)) / IntereventTimes.LOG_BUCKET)

    def add(self, key, time):
        try:
            last_time = self.last_seen[key]
            dt = self.discretize((time - last_time).total_seconds())
            self.interevent_times[dt] += 1
        except KeyError:
            dt = self.discretize((time - self.sampling_begin_time).total_seconds())
            self.first_time_seen[dt] += 1
        self.last_seen[key] = time

    def finish(self):
        for key, time in self.last_seen.iteritems():
            dt = self.discretize((self.sampling_end_time - time).total_seconds())
            self.last_time_seen[dt] += 1

# We want to calculate the interevent time distribution both for users'
# actions and page edits, therefore we create a dictionary to hold these
# histograms
interevent_times = dict()
for entity in ['users', 'pages']:
    interevent_times[entity] = IntereventTimes(
        datetime.strptime(DATE_RANGE[0], DATE_RANGE_FORMAT),
        datetime.strptime(DATE_RANGE[1], DATE_RANGE_FORMAT))

input_file = gzip.open(INPUT_FILE, 'r')
for line in input_file:
    title, namespace, page_id, rev_id, timestamp, user_id, user_name, ip = \
        line[:-1].split('\t')
    if timestamp < DATE_RANGE[0]:
        continue
    if timestamp >= DATE_RANGE[1]:
        break
    # We only keep registered users, and need to strip user ID 0 due to
    # a logging bug (http://en.wikipedia.org/wiki/User:0)
    if user_id != '' and user_id != '0':
        user_id = int(user_id)
        page_id = int(page_id)
        timestamp = datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%SZ')
        interevent_times['users'].add(user_id, timestamp)
        interevent_times['pages'].add(page_id, timestamp)
input_file.close()

for entity in ['users', 'pages']:
    interevent_times[entity].finish()
    output_file = gzip.open(OUTPUT_FILE_PATTERN % entity, 'w')
    for dt, count in interevent_times[entity].first_time_seen.iteritems():
        output_file.write('\t'.join(map(str, ['before_first', dt, count])) + '\n')
    for dt, count in interevent_times[entity].interevent_times.iteritems():
        output_file.write('\t'.join(map(str, ['interevent', dt, count])) + '\n')
    for dt, count in interevent_times[entity].last_time_seen.iteritems():
        output_file.write('\t'.join(map(str, ['after_last', dt, count])) + '\n')
    output_file.close()

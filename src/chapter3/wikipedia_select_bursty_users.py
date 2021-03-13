'''
The time differences between edits for any user for one week.
'''

import sys, gzip
from collections import defaultdict
from datetime import datetime


INPUT_FILE = 'data/wikipedia/revisions_time_sorted.tsv.gz'
OUTPUT_FILE = 'data/wikipedia/revisions_only_for_one_week.tsv.gz'

DATE_RANGE = ('2013-01-01T00:00:00Z', '2013-01-08T00:00:00Z')

input_file = gzip.open(INPUT_FILE, 'r')
output_file = gzip.open(OUTPUT_FILE, 'w')
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
        output_file.write('\t'.join([user_id, page_id, timestamp]) + '\n')
input_file.close()
output_file.close()

'''
Create a weighted, directed network from Wikipedia user talk page interactions.
'''

import gzip, re
from collections import defaultdict


INPUT_FILE = 'data/wikipedia/revisions_time_sorted.tsv.gz'
OUTPUT_FILE = 'data/wikipedia/talk_network.tsv.gz'

DATE_RANGE = ['2013-01-01T00:00:00', '2013-02-01T00:00:00']

# `edges` is a doubly-keyed dictionary to keep the number of times when
# an edit happened.
edges = defaultdict(lambda: defaultdict(int))
# The mapping between the user name and the arbitrary user integer index.
user_name_to_index = dict()


def map_string_to_index(mapping, string):
    '''Return the 0-based index for the user name, or a new user ID if we
       have not seen the user before.'''
    if string in mapping:
        index = mapping[string]
    else:
        index = len(mapping)
        mapping[string] = index
    return index


# The regexp pattern to parse out the user name from the page title
pattern_user_name = re.compile('^User talk:([^/]*)/*.*')
# The pattern to identify a bot (any user name that contains a word that ends
# on 'bot')
pattern_bot = re.compile('.*[Bb][Oo][Tt]\\b')
input_file = gzip.open(INPUT_FILE, 'r')
for line in input_file:
    title, namespace, page_id, rev_id, timestamp, user_id, user_name, ip = \
        line[:-1].split('\t')
    if timestamp >= DATE_RANGE[1]:
        # The input file is sorted by time so we can finish the loop
        # in this case.
        break
    if namespace == '3' and user_id != '' and user_id != '0' and \
    timestamp >= DATE_RANGE[0] and timestamp < DATE_RANGE[1]:
        m = pattern_user_name.match(title)
        if m:
            commenter, target_user = (user_name, m.group(1))
            if pattern_bot.match(commenter) or \
            pattern_bot.match(target_user) or commenter == target_user:
                # A bot is making or creating the edit, or a self-edit.
                continue
            commenter = map_string_to_index(user_name_to_index, commenter)
            target_user = map_string_to_index(user_name_to_index, target_user)
            edges[commenter][target_user] += 1
input_file.close()

output_file = gzip.open(OUTPUT_FILE, 'w')
for commenter, target_users in edges.iteritems():
    for target_user, times in target_users.iteritems():
        output_file.write(
            '\t'.join(map(str, [commenter, target_user, times])) + \
            '\n')
output_file.close()

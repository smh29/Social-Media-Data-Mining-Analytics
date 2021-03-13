'''
For the Livejournal social network, output the degrees of all nodes, and their
local clustering coefficients.
'''

import gzip
from collections import defaultdict
import sys


INPUT = 'data/livejournal/livejournal-links.txt.gz'
OUTPUT = 'data/livejournal/link_counts.tsv.gz'


# The graph is a directed graph.
outgoing = defaultdict(set)     # The nodes at the ends of outgoing links.
incoming = defaultdict(set)     # The nodes at the other ends of incoming links.
users = set()                   # All the users.
with gzip.open(INPUT) as f:
    for line in f:
        # Convert node IDs to integers to save space.
        source, destination = map(int, line.rstrip().split('\t'))
        outgoing[source].add(destination)
        incoming[destination].add(source)
        users.add(source)
        users.add(destination)

with gzip.open(OUTPUT, 'w') as out:
    for u in users:             # Need to iterate through all the users.
        triangle_links = 0      # The number of links among neighbors.
        neighbors = incoming[u].copy()
        neighbors.update(outgoing[u])           # Holds all the neighbors.
        for v in neighbors:
            if v in outgoing:
                # For all outgoing edges of v if it has any.
                for e in outgoing[v]:
                    if e != u and e in neighbors:
                        triangle_links += 1
        # Just so we have all the data we store the out- and in-degree,
        # the number of distinct neighbors, and the number of directed edges
        # between the neighbors.
        out.write('\t'.join(map(str, [len(outgoing[u]), len(incoming[u]),
                                      len(neighbors), triangle_links]))
                  + '\n')

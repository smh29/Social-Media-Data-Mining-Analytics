'''
Randomize where the network links point to so as to destroy clustering among
the nodes, if any.
'''

INPUT = 'data/livejournal/livejournal-links.txt.gz'
OUTPUT = 'data/livejournal/link_counts_rewired_10x.tsv.gz'

import gzip, random
from collections import defaultdict
import sys


def triangle_counts(output_file, users, incoming, outgoing):
    with gzip.open(output_file, 'w') as out:
        done = 0
        for u in users:
            triangle_links = 0
            neighbors = incoming[u].copy()
            neighbors.update(outgoing[u])
            for v in neighbors:
                if v in outgoing:
                    for e in outgoing[v]:
                        if e != u and e in neighbors:
                            triangle_links += 1
            out.write('\t'.join(map(str, [len(outgoing[u]), len(incoming[u]),
                                          len(neighbors), triangle_links]))
                      + '\n')
            done += 1
            if done % 1000 == 0:
                sys.stderr.write(str(done / 1e6) + 'M    \r')


edges = list()                  # The list of all edges with (from, to) tuples.
with gzip.open(INPUT) as f:
    for line in f:
        # Convert node IDs to integers to save space.
        source, destination = map(int, line.rstrip().split('\t'))
        edges.append([source, destination])

print 'The number of edges:', len(edges)

rewire_rounds = 10 * len(edges)             # The number of randomization steps.
for rewire_round in xrange(0, rewire_rounds):
    e1 = random.randint(0, len(edges) - 1)  # Choose the first edge randomly.
    e2 = random.randint(0, len(edges) - 1)  # Choose the second edge randomly.
    e2_dest = edges[e2][1]                  # Swap the edges (we don't need to
    edges[e2][1] = edges[e1][1]             # watch out for the case when
    edges[e1][1] = e2_dest                  # e1 == e2, it just won't do anything).

outgoing = defaultdict(set)
incoming = defaultdict(set)
users = set()
for (source, destination) in edges:
    outgoing[source].add(destination)
    incoming[destination].add(source)
    users.add(source)
    users.add(destination)

triangle_counts(OUTPUT, users, incoming, outgoing)

'''
From the Wikipedia talk network, output the degrees of all nodes, and their
local clustering coefficients.
'''

INPUT = 'data/wikipedia/talk_network.tsv.gz'

import gzip
from collections import defaultdict

edges = defaultdict(set)
edge_count = 0
nodes = set()
with gzip.open(INPUT) as f:
    for line in f:
        commenter, target_user, times = line.rstrip().split('\t')
        edges[commenter].add(target_user)
        edge_count += 1
        nodes.add(commenter)
        nodes.add(target_user)

print 'Directed edge count:', edge_count
print 'Node count:', len(nodes)

friends = defaultdict(set)
edge_count = 0
nodes = set()
for u, links in edges.iteritems():
    for v in links:
        if v in edges and u in edges[v]:
            friends[u].add(v)
            edge_count += 1
            nodes.add(u)

print 'Undirected edge count:', edge_count
print 'Node count:', len(nodes)

for u in friends.iterkeys():
    u_neighbors = 0
    triangle_links = 0
    for v in friends[u]:
        u_neighbors += 1
        for w in friends[v]:
            if w != u and w in friends[u]:
                triangle_links += 1
    if u_neighbors > 1:
        clustering_coefficient = triangle_links / (u_neighbors * (u_neighbors - 1))
        print '\t'.join(map(str, [u_neighbors, clustering_coefficient]))

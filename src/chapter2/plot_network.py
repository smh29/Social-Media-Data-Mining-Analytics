'''
Plot a local neighborhood of a social network satisfying certain conditions.
'''

import gzip, random
import networkx as nx
import networkx.algorithms.traversal.breadth_first_search as breadth_first_search
import matplotlib.pyplot as plt

MAX_DIST = 3
INPUT_FILE = 'data/wikipedia/talk_network.tsv.gz'

graph = nx.Graph()
with gzip.open(INPUT_FILE, 'r') as input_file:
    for line in input_file:
        commenter, target_user, times = line.rstrip().split('\t')
        if commenter != target_user:
            # Do not store self-edits.
            commenter, target_user = map(int, [commenter, target_user])
            graph.add_edge(commenter, target_user)

N = graph.number_of_nodes()
E = graph.number_of_edges()
print N, E

while True:
    # Choose a random node for a center.
    center = random.randint(0, N - 1)
    # The distances of the nodes from the center we have seen so far.
    distances = { center: 0 }
    # Walk the graph with a BFS, starting from 'center'. The edges are
    # returned in an order corresponding to BFS.
    for source, target in breadth_first_search.bfs_edges(graph, center):
        if target not in distances:
            if distances[source] == MAX_DIST:
                # The very first time we touch a node that is beyond our
                # maximum depth, we stop walking.
                break
            else:
                distances[target] = distances[source] + 1

    # We create a 'small_graph' that contains only the nodes that we walked
    # and the edges between them.
    small_graph = nx.Graph()
    for node_found in distances.iterkeys():
        for neighbor in graph.neighbors(node_found):
            if neighbor in distances:
                small_graph.add_edge(node_found, neighbor)

    # We decide whether the local graph we found would look "good" (a medium
    # density of edges, not too many nodes, and the node with the most
    # connections has at most 200 neighbors).
    edge_fraction = float(small_graph.number_of_edges()) / \
        small_graph.number_of_nodes()
    max_degree = None
    for node in small_graph.nodes():
        if max_degree is None or small_graph.degree(node) > max_degree:
            max_degree = small_graph.degree(node)
    if small_graph.number_of_edges() < 3000 and \
    edge_fraction > 2 and edge_fraction < 4 and max_degree < 200:
        # If this seems to be a good neighborhood, lay it out with the
        # force-directed spring layout algorithm.
        print 'Center:', center
        pos = nx.spring_layout(small_graph, iterations=200)
        colors = [(3 * [max([0, (distances[n] - 1.0) / (MAX_DIST - 1)])])
                       for n in small_graph.nodes()]
        nx.draw(small_graph, pos, node_size=40, node_color=colors,
            with_labels=False)
        nx.draw_networkx_nodes(small_graph, pos,
            nodelist=[center], node_size=200, node_color=[1, 0, 0])
        plt.show()
        break

print small_graph.number_of_edges()

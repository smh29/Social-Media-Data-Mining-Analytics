'''
Simulate Polya's generalized urn model.
'''

# The number of total draws (time steps).
ROUNDS = 10000

# The parameter p of the model.
P = 0.2

import random
from collections import defaultdict
import matplotlib.pyplot as plt

# The number of balls in each of the bins; bins are indexed by integers.
bin_balls = defaultdict(int)

# Start with one bin having one ball only.
bin_balls[0] = 1

for round in xrange(0, ROUNDS):
    if random.random() < P:
        # Create a new bin with probability P.
        bin_balls[len(bin_balls)] = 1
    else:
        # Otherwise add a ball to a bin based on preferential attachment.
        threshold = random.randint(1, round + 1)
        s = 0
        for b, balls in bin_balls.iteritems():
            s += balls
            if s >= threshold:
                # Choose this bin for the ball.
                bin_balls[b] += 1
                break

# Calculate the ball distribution across the bins.
ball_dist = defaultdict(int)
for k in bin_balls.itervalues():
    ball_dist[k] += 1

plt.xscale('log'); plt.yscale('log')
plt.xlabel('Ball count'); plt.ylabel('Bin count')
plt.scatter(ball_dist.keys(), ball_dist.values())
plt.show()

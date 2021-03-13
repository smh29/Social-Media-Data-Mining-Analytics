import numpy as np

mean0 = mean(diffs)
# A constant to correct for the truncation, but keep the means the same.
correction_due_to_quatization = 1.22

memoryless = np.random.exponential(
    1.0 / (correction_due_to_quatization * mean0), len(diffs)).astype(int)
print mean0, mean(memoryless)

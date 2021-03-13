import random

class ReservoirSample():
    '''Perform reservoir sampling to get a uniform sample from any number
       of elements.'''

    def __init__(self, sample_count):
        '''sample_count is the desired number of sample points
           self.items contains the sample after we're finished'''
        self.items = []
        self.sample_count = sample_count
        self.index = 0

    def add_item(self, item):
        '''Add an item to the reservoir.'''
        if self.index < self.sample_count:
            self.items.append(item)
        else:
            r = random.randint(0, self.index - 1)
            if r < self.sample_count:
                self.items[r] = item
        self.index += 1

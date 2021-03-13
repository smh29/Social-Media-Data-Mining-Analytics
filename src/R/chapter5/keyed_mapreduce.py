from mapreduce_def import map2


def keyed_mapreduce(items, mapfn, redfn):
    # Do the Map phase
    mapped = map2(mapfn, items)
    # Partition values by key
    keyed_values = {}
    for (key, value) in mapped:
        values = keyed_values.get(key, [])
        values.append(value)
        keyed_values[key] = values
    # Do the reduce phase
    for (key, values) in keyed_values.iteritems():
        for out in redfn(key, values):
            yield out


def map1(x):
    '''A sample map function.

    Notice that we return something iterable. We can use this to filter,
    or expand the input by returning 0 or more than 1 items, respectively.
    '''
    key = x % 3
    value = x
    yield (key, value)


def red1(key, values):
    '''A sample reduce function.

    Again, we return something iterable for flexibility.
    '''
    yield (key, sum(values))


if __name__ == '__main__':
    print dict(keyed_mapreduce(range(0, 100), map1, red1))
    # Prints {0: 1683, 1: 1617, 2: 1650}

    print {
        0: sum([x for x in range(0, 100) if x % 3 == 0]),
        1: sum([x for x in range(0, 100) if x % 3 == 1]),
        2: sum([x for x in range(0, 100) if x % 3 == 2])
    }
    # Prints the same as above

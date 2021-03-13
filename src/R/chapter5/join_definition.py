from itertools import groupby


def get_0(item):
    return item[0]


def get_1(item):
    return item[1]


def to_dict(key_values):
    '''Build a dict of key, and the list of all values for that key.'''
    return dict([(k, list(v)) for (k, v) in
                 groupby(sorted(key_values, key=get_0), get_0)])


def concat_map(f, xs):
    '''Map each element x to f(x), which is itself a list, then concatenate.'''
    return [y for x in xs for y in f(x)]


def cross_product(list1, list2):
    return [(x, y) for x in list1 for y in list2]


def innerjoin(list1, list2):
    '''Return a list of (k, (v, w)) for all k, v, w such that
    k, v is in list1, and k, w is in list2.'''
    table1 = to_dict(list1)
    table2 = to_dict(list2)

    # Here's is the cross product for each key
    def key_cross(k):
        return map(lambda v: (k, v), cross_product(map(get_1, table1[k]),
                                                   map(get_1, table2[k])))

    both_keys = set(table1.keys()) & set(table2.keys())
    return concat_map(key_cross, both_keys)


if __name__ == '__main__':
    print innerjoin(map(lambda x: (x / 2, 2 * x), range(0, 5)),
                    map(lambda x: (x / 2, 3 * x), range(0, 3)))
# Prints:
# [(0, (0, 0)), (0, (0, 3)), (0, (2, 0)), (0, (2, 3)), (1, (4, 6)), (1, (6, 6))]
# because 0 / 2 == 1 / 2 == 0, etc.
# so the first list is  [(0, 0), (0, 2), (1, 4), (1, 6), (2, 8)]
#    the second list is [(0, 0), (0, 3), (1, 6)]
# cross product for key 0 = [0, 2] x [0, 3] = [(0, 0), (0, 3), (2, 0), (2, 3)]
# cross product for key 1 = [4, 6] x [6] = [(4, 6), (6, 6)]
# cross product for key 2 = [8] x [] = []

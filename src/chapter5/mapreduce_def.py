def map2(fun, items):
    '''The Map operation in MapReduce.

    Slightly different from Python's standard "map".
    '''
    result = []
    for x in items:
        result.extend(fun(x))
    return result


def reduce(fun, items):
    '''The Reduce operation in MapReduce.'''
    result = None
    for x in items:
        if result is not None:
            result = fun(result, x)
        else:
            result = x
    return result


def times2(x):
    yield 2 * x


def add(x, y):
    return x + y


if __name__ == '__main__':
    print map2(times2, [1, 2, 3])
    # Prints [2, 4, 6]

    print reduce(add, [1, 2, 3])
    # Prints 6

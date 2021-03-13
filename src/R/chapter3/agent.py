def agent(start, minDiff):
    '''Return a function that transforms an input iterator according to the
    impatient filtering.'''

    def __inner__(interTimes):
      now = start
      thisDiff = minDiff
      lastTime = now
      for interval in interTimes:
        now = now + interval
        if interval > thisDiff:
            yield now - lastTime
            thisDiff = minDiff
            lastTime = now
        else:
          # We get impatient and lower the barrier.
          thisDiff = thisDiff * 0.25

    return __inner__

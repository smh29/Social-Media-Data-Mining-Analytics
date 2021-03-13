'''
Count the distinct URLs in all the HTML files in a directory.

Run as
python src/chapter6/url_count.py data/mapreduce
'''

import sys
from os import listdir
from os.path import isfile, join
from HTMLParser import HTMLParser

from keyed_mapreduce import keyed_mapreduce


# Create a subclass and override the handler methods.
class UrlParser(HTMLParser):
    def __init__(self):
        HTMLParser.__init__(self)
        self.__urls__ = []

    def urls(self):
        '''Get the URLS from the last feed, and empty the list.'''
        for url in self.__urls__:
            yield url
        self.__urls__[:] = []

    def handle_starttag(self, tag, attrs):
        '''Get the links, which are in anchor <a href=""> tags.'''
        if tag == 'a':
            self.__urls__.extend(
                [url for (href, url) in attrs if href == 'href'])


def urls(fileline):
    '''Return 1 as the value for every URL appearing in the line.'''
    (filename, line) = fileline
    parser.feed(line)
    return [(url, 1) for url in parser.urls()]


def plus(key, values):
    yield (key, sum(values))


def filesource(files):
    '''Creates an iterator of (filename, line) pairs.

    Allows us to operate on many files.
    '''
    for fname in files:
        with open(fname, 'r') as f:
            for line in f:
                yield (fname, line)


if __name__ == '__main__':
    # Each mapper will need an html parser to read the anchor tags
    parser = UrlParser()

    path = sys.argv[1]
    htmlfiles = [join(path, f) for f in listdir(path)
                 if isfile(join(path, f)) and f.endswith('html')]
    for urlcount in keyed_mapreduce(filesource(htmlfiles), urls, plus):
        print urlcount

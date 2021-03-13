'''
Count the number of times users contributed to some kind of content
within the given time frame.

This script assumes that the Wikipedia page revision history dataset
has been downloaded by running the src/chapter2/wikipedia/get_data.sh script.

Documentation for the XML fields can be found at
http://www.mediawiki.org/wiki/Manual:Revision_table
'''

import gzip
from xml.sax import make_parser, handler


INPUT_FILE = 'data/wikipedia/enwiki-stub-meta-history.xml.gz'
OUTPUT_FILE = 'data/wikipedia/revisions.tsv.gz'


class Node(dict):
    '''A Node object represents an XML node of interest to us.'''

    def __init__(self, name):
        self.name = name
        self.parent = None
        self.children = []

    def add_child(self, child):
        child.parent = self
        self.children.append(child)

    def clear(self):
        self.parent = None
        self.children = []
        super(Node, self).clear()


class WikipediaXMLReader(handler.ContentHandler):

    def __init__(self, process_revision):
        handler.ContentHandler.__init__(self)

        # The callback function to be called when all the fields are ready
        # for a revision
        self._process_revision = process_revision

        # The node corresponding to a Wikipedia page
        self._page = Node('page')

        # The current node in the XML tree during parsing
        self._current = self._page

    def startElement(self, name, attrs):
        if name == 'page':
            self._page.clear()
            self._current = self._page
        elif name == 'revision' or name == 'contributor':
            new_node = Node(name)
            self._current.add_child(new_node)
            self._current = new_node
        last_node = self._current.name
        self._store_into = None
        if (last_node == 'page' and name in set(['title', 'ns', 'id'])) or \
            (last_node == 'revision' and name in set(['id', 'timestamp'])) or \
            (last_node == 'contributor' and name in set(['id', 'username', 'ip'])):
                self._store_into = name

    def endElement(self, name):
        if name == 'page':
            self._process_revision(self._page)
        elif name == 'revision' or name == 'contributor':
            self._current = self._current.parent
        self._store_into = None

    def characters(self, content):
        # The character content may be returned in chunks, we need to build
        # the content part up piecewise
        if self._store_into is not None:
            self._current[self._store_into] = \
            self._current.get(self._store_into, '') + content


class ProcessRevisions():
    '''Process the revision data.'''

    def __init__(self, output):
        self._output = output

    def process_revision(self, page):
        for rev in page.children:
            if len(rev.children) == 0:
                contributor = dict()
            else:
                contributor = rev.children[0]
            self._output.write('\t'.join([
                page.get('title', ''),
                page.get('ns', ''),
                page.get('id', ''),
                rev.get('id', ''),
                rev.get('timestamp', ''),
                contributor.get('id', ''),
                contributor.get('username', ''),
                contributor.get('ip' , '')
            ]).encode('utf-8'))
            self._output.write('\n')


input_file = gzip.open(INPUT_FILE, 'r')
output_file = gzip.open(OUTPUT_FILE, 'w')

# This is the object to process every Wikipedia edit revision
process_revisions = ProcessRevisions(output_file)

parser = make_parser()
parser.setContentHandler(WikipediaXMLReader(process_revisions.process_revision))
parser.parse(input_file)

input_file.close()
output_file.close()

'''
Preprocess the Stackexchange downloads.

The Stack Exchange data dumps:
https://archive.org/details/stackexchange

The license to use the data:
http://blog.stackoverflow.com/2009/06/stack-overflow-creative-commons-data-dump/

The database schema documentation:
http://meta.stackexchange.com/questions/2677/database-schema-documentation-for-the-public-data-dump-and-sede
'''

import xml.sax, gzip, re
import bs4
import nltk.tokenize
import nltk.corpus
import nltk.stem.snowball
from collections import defaultdict


# The Stack Exchange posts file.
INPUT_FILE = 'data/stack_exchange/dumps/Posts.xml'

# The outputs for the posts and the vocabulary.
POSTS_FILE = 'data/stack_exchange/posts.tsv.gz'
VOCABULARY_FILE = 'data/stack_exchange/vocabulary.tsv.gz'


class StackExchangeXMLReader(xml.sax.handler.ContentHandler):

    def __init__(self, record_processor):
        # Precompile the regex pattern for keeping alphanumeric characters only
        self._alphanumeric_pattern = re.compile('[\W_]+')
        self._record_processor = record_processor
        self._n = 0
        # Use NLTK's built-in stop word list for the English language
        # The stopwords corpora may need to be downloaded for NLTK, the command
        # for this would be:
        # python -c "import nltk; nltk.download('stopwords')"
        # For the details see http://www.nltk.org/data.html
        self._stopwords = set(nltk.corpus.stopwords.words('english'))
        self._stemmer = nltk.stem.snowball.SnowballStemmer('english')

    def startElement(self, name, attrs):
        if name != 'row':
            return
        if attrs['PostTypeId'] in set(['1', '2']):
            # Split up the post into tokens (words)
            tokens = self.tokenize_text(attrs['Body'])
            # Remove the stopwords
            tokens = [t for t in tokens if t not in self._stopwords]
            self._record_processor(attrs, tokens)

    def tokenize_text(self, text):
        # Clean up the text from HTML tags first
        html_cleaned = bs4.BeautifulSoup(text).get_text()
        # Break words at whitespaces and punctuation marks next
        tokens = nltk.tokenize.wordpunct_tokenize(html_cleaned)
        result = []
        for token in tokens:
            # Keep only the alphanumeric letters in the words
            token = self._alphanumeric_pattern.sub('', token)
            token = self._stemmer.stem(token)
            if token:
                result.append(token.lower())
        return result


class Posts():
    # The information recorded for each post is described at
    # http://meta.stackexchange.com/questions/2677/database-schema-documentation-for-the-public-data-dump-and-sede
    ATTRIBUTES_KEPT = ['Id', 'PostTypeId', 'ParentId', 'OwnerUserId',
                       'CreationDate', 'ViewCount', 'FavoriteCount']

    def __init__(self, vocabulary_file, posts_file):
        self._vocabulary_file = vocabulary_file
        self._posts_file = posts_file
        self._vocabulary = defaultdict(int)

    def process_record(self, attrs, tokens):
        for token in tokens:
            self._vocabulary[token] += 1
        # The post tags are in a format "<mars><history>", so we want to
        # keep only the tags without the <> separators with the following regex
        tags = re.findall(r'''\s*<([^>]+)>\s*''', attrs.get('Tags', ''))
        self._posts_file.write('\t'.join(map(str, [attrs.get(field, '')
            for field in Posts.ATTRIBUTES_KEPT] + [' '.join(tags),
                ' '.join(tokens)])) + '\n')

    def finish(self):
        for token, frequency in sorted(self._vocabulary.items(),
                                       key=lambda item: item[1], reverse=True):
            self._vocabulary_file.write('\t'.join(map(str, [token, frequency])) + '\n')

# We go through the input file, parse the text, and supply that to the
# appropriate function to process it (to create the vocabulary
# or to create the posts input file for R).
input_file = open(INPUT_FILE, 'r')
vocabulary_file = gzip.open(VOCABULARY_FILE, 'w')
posts_file = gzip.open(POSTS_FILE, 'w')

record_processor = Posts(vocabulary_file, posts_file)
record_handler = StackExchangeXMLReader(record_processor.process_record)

parser = xml.sax.make_parser()
parser.setContentHandler(record_handler)
parser.parse(input_file)
record_processor.finish()

input_file.close()
vocabulary_file.close()
posts_file.close()

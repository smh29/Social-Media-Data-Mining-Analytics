# Download the Stack Exchange metadata and posts data sets from the
# "Science Fiction & Fantasy" topic.

OUTPUT_DIR=data/stack_exchange

cd $OUTPUT_DIR

# Download the archive file.
curl -L https://archive.org/download/stackexchange/scifi.stackexchange.com.7z \
    -o scifi.stackexchange.com.7z

# Extract.
mkdir dumps
cd dumps
7z e ../scifi.stackexchange.com.7z

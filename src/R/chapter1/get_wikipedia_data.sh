# Download the Wikipedia page revision history dataset.

BACKUP_DEFAULT_DATE=latest

if [ "$1" != "" ]; then
    backup_date=$1
else
    backup_date=$BACKUP_DEFAULT_DATE
fi

curl https://dumps.wikimedia.org/enwiki/$backup_date/enwiki-$backup_date-stub-meta-history.xml.gz \
    -o data/wikipedia/enwiki-stub-meta-history.xml.gz

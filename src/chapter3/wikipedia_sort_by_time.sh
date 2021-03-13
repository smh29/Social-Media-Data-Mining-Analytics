# Sort the Wikipedia revision file with parallelized external sort and
# compression, using half of the RAM.

pigz --decompress --stdout < data/wikipedia/revisions.tsv.gz | \
sort --key=5 --field-separator=$'\t' --buffer-size=50% --parallel=$(nproc) | \
pigz --stdout > data/wikipedia/revisions_time_sorted.tsv.gz

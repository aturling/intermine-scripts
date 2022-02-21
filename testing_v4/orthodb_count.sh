#!/bin/bash  

#######################################################
# orthodb_count.sh
#
# Check database for correct number of OrthoDB genes
# and homologues.
#######################################################

all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Get dataset id for OrthoDB to help simplify queries
dataset_name="OrthoDB data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

# Use script to count total number of expected homologues
this_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$this_path"
if [ ! -d "temp" ]; then
    mkdir temp
fi

orthodb_filename=$(find /db/*/datasets/OrthoDB/ -maxdepth 1 -name *.tab)
echo "Counting expected number of OrthoDB homologues from input file: $orthodb_filename..."
outfile="temp/orthodb_count.txt"
if [ ! -f "$outfile" ]; then
    echo "(This will take a while)"
    ../data_parsing/count_homologues.sh "$orthodb_filename" | tee >(tail -n 1 > $outfile)
fi
file_count=$(grep -oE "[0-9]+" "$outfile")
echo "done"

echo "Querying database for total number of OrthoDB homologues..."
dbcount=$(psql ${dbname} -c "select count(id) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id}" -t -A)
echo "done"

if [ ! $file_count -eq $dbcount ]; then
    echo "WARNING: expected $file_count homologues from input file, but $dbcount OrthoDB homologues in database!"
    all_counts_correct=0
else
    echo "OrthoDB homologues count correct ($dbcount homologues)"
fi

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

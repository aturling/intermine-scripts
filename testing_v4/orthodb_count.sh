#!/bin/bash  

#######################################################
# orthodb_count.sh
#
# Check database for correct number of OrthoDB genes
# and homologues.
#
# Note: this script stores homologue counts from input
# files in an output file in the local temp directory.
# If the input files change, this output file will need
# to be deleted in order to have the counts recomputed.
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
echo "OrthoDB input file: $orthodb_filename"

# First check total number of OrthoDB homologues
echo "Counting expected number of OrthoDB homologues from input file..."
outfile="temp/orthodb_count.txt"
if [ ! -f "$outfile" ]; then
    echo "(This will take a while)"
    ../data_parsing/count_homologues.sh "$orthodb_filename" | tee >(tail -n 1 > $outfile)
fi
file_count=$(grep -oE "[0-9]+" "$outfile")

echo "Querying database for total number of OrthoDB homologues..."
dbcount=$(psql ${dbname} -c "select count(id) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id}" -t -A)

if [ ! $file_count -eq $dbcount ]; then
    echo "WARNING: expected $file_count homologues from input file, but $dbcount OrthoDB homologues in database!"
    all_counts_correct=0
else
    echo "OrthoDB homologues count correct ($dbcount homologues)"
fi
echo

# Next check number of clusters
echo "Counting expected number of clusters from input file..."
file_count=$(cut -f 2 "$orthodb_filename" | sort | uniq | wc -l)
echo "Querying database for number of OrthoDB clusters in Homologue table..."
dbcount1=$(psql ${dbname} -c "select count(distinct(h.clusterid)) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id} and h.clusterid is not null" -t -A)
echo "Querying database for number of OrthoDB OrthologueClusters..."
dbcount2=$(psql ${dbname} -c"select count(oc.id) from orthologuecluster oc join datasetsorthologuecluster doc on doc.orthologuecluster = oc.id where doc.datasets=${dataset_id}" -t -A)
if [ ! $dbcount1 -eq $dbcount2 ]; then
    echo "WARNING: found $dbcount clusters in Homologue table, but $dbcount2 clusters in OrthologueCluster table!"
    all_counts_correct=0
fi
if [ ! $dbcount1 -eq $file_count ]; then
    echo "WARNING: Expected $file_count clusters from input file, but $dbcount1 clusters in database!"
    all_counts_correct=0
else
    echo "OrthoDB cluster count correct ($dbcount1 clusters)"
fi
echo

# Next check number of genes
echo "Counting expected number of distinct gene IDs from input file..."
file_count=$(cut -f 3 "$orthodb_filename" | sort | uniq | wc -l)
echo "Querying database for number of OrthoDB gene IDs in homologue table..."
dbcount=$(psql ${dbname} -c "select count(distinct(geneid)) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id}" -t -A)
if [ ! $file_count -eq $dbcount ]; then
    echo "WARNING: Expected $file_count genes, but $dbcount genes in Homologue table!"
    all_counts_correct=0
else
    echo "OrthoDB gene count correct ($dbcount distinct genes)"
fi

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

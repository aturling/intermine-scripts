#!/bin/bash  

#######################################################
# aquamine_ortho_count.sh
#
# Check database for correct number of AquaMine-Ortho 
# genes and homologues.
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

# Get dataset id for AquaMine-Ortho to help simplify queries
dataset_name="AquaMine-Ortho data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "AquaMine-Ortho data set not found in database"
    exit 1;
fi

# Use script to count total number of expected homologues
this_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$this_path"
if [ ! -d "temp" ]; then
    mkdir temp
fi

# First check total number of AquaMine-Ortho homologues
echo "Counting expected number of AquaMine-Ortho homologues from input files..."
outfile="temp/aquamine_ortho_count.txt"
total_file_count=0
files=$(find /db/*/datasets/AquaMine-Ortho/ -maxdepth 1 -name *.tab)
if [ ! -f "$outfile" ]; then
    echo "(This will take a while)"
    echo "" > $outfile
    for file in $files; do
        echo "Analyzing input file $file..."
        ../data_parsing/count_homologues.sh "$file" | tee >(tail -n 1 >> $outfile)
        this_file_count=$(tail -n 1 "$outfile" | grep -oE "[0-9]+")
        echo "this count is: $this_file_count"
        total_file_count=$((total_file_count + this_file_count))
        echo "total so far: $total_file_count"
    done
    echo "Total homologues in all files: $total_file_count" >> $outfile
else
    # Grab number from last run
    total_file_count=$(tail -n 1 "$outfile" | grep -oE "[0-9]+")
fi

echo "Querying database for total number of AquaMine-Ortho homologues..."
dbcount=$(psql ${dbname} -c "select count(id) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id}" -t -A)

if [ ! $total_file_count -eq $dbcount ]; then
    echo "WARNING: expected $total_file_count homologues from input file, but $dbcount AquaMine-Ortho homologues in database!"
    all_counts_correct=0
else
    echo "AquaMine-Ortho homologues count correct ($dbcount homologues)"
fi
echo

# Next check number of clusters
echo "Counting expected number of clusters from input file..."
file_count=$(cat /db/*/datasets/AquaMine-Ortho/*.tab | cut -f 2 | sort | uniq | wc -l)
echo "Querying database for number of AquaMine-Ortho clusters in Homologue table..."
dbcount1=$(psql ${dbname} -c "select count(distinct(h.clusterid)) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id} and h.clusterid is not null" -t -A)
echo "Querying database for number of AquaMine-Ortho OrthologueClusters..."
dbcount2=$(psql ${dbname} -c"select count(oc.id) from orthologuecluster oc join datasetsorthologuecluster doc on doc.orthologuecluster = oc.id where doc.datasets=${dataset_id}" -t -A)
if [ ! $dbcount1 -eq $dbcount2 ]; then
    echo "WARNING: found $dbcount clusters in Homologue table, but $dbcount2 clusters in OrthologueCluster table!"
    all_counts_correct=0
else
    echo "Cluster count in Homologue table matches number of clusters in OrthologueCluster table as expected"
fi
if [ ! $dbcount1 -eq $file_count ]; then
    echo "WARNING: Expected $file_count clusters from input file, but $dbcount1 clusters in database!"
    all_counts_correct=0
else
    echo "AquaMine-Ortho cluster count correct ($dbcount1 clusters)"
fi
echo

# Next check number of genes
echo "Counting expected number of distinct gene IDs from input file..."
file_count=$(cat /db/*/datasets/AquaMine-Ortho/*.tab | cut -f 3 | sort | uniq | wc -l)
echo "Querying database for number of AquaMine-Ortho gene IDs in homologue table..."
dbcount=$(psql ${dbname} -c "select count(distinct(geneid)) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id}" -t -A)
if [ ! $file_count -eq $dbcount ]; then
    echo "WARNING: Expected $file_count genes, but $dbcount genes in Homologue table!"
    all_counts_correct=0
else
    echo "AquaMine-Ortho gene count correct ($dbcount distinct genes)"
fi

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

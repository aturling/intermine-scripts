#!/bin/bash  

#######################################################
# gpluse_orthologs_count.sh
#
# Check database for correct number of GplusE genes
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
dataset_name="GplusE orthologs data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "GplusE orthologs data set not found in database"
    exit 1;
fi

# Use script to count total number of expected homologues
this_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$this_path"
if [ ! -d "temp" ]; then
    mkdir temp
fi

ortho_filename=$(find /db/*/datasets/GPLUSE/orthologs/ -maxdepth 1 -name *.tab)
echo "GplusE orthologs input file: $ortho_filename"

# First check total number of GplusE homologues
echo "Counting expected number of GpluseE homologues from input file..."
outfile="temp/gpluse_orthologs_count.txt"
if [ ! -f "$outfile" ]; then
    echo "(This will take a while)"
    ../data_parsing/count_homologues.sh "$ortho_filename" | tee >(tail -n 1 > $outfile)
fi
file_count=$(grep -oE "[0-9]+" "$outfile")

echo "Querying database for total number of GplusE homologues..."
dbcount=$(psql ${dbname} -c "select count(id) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id}" -t -A)

if [ ! $file_count -eq $dbcount ]; then
    echo "WARNING: expected $file_count homologues from input file, but $dbcount GplusE homologues in database!"
    all_counts_correct=0
else
    echo "GplusE homologues count correct ($dbcount homologues)"
fi
echo

# Next check number of genes
echo "Counting expected number of distinct gene IDs from input file..."
file_count=$(cut -f 3 "$ortho_filename" | sort | uniq | wc -l)
echo "Querying database for number of GplusE gene IDs in homologue table..."
dbcount=$(psql ${dbname} -c "select count(distinct(geneid)) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id}" -t -A)
if [ ! $file_count -eq $dbcount ]; then
    echo "WARNING: Expected $file_count genes, but $dbcount genes in Homologue table!"
    all_counts_correct=0
else
    echo "GplusE gene count correct ($dbcount distinct genes)"
fi

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

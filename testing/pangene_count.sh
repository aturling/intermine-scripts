#!/bin/bash  

#######################################################
# pangene_count.sh
#
# Check database for correct number of PanGene yntelogs.
#
# Note: this script stores syntelog counts from input
# files in an output file in the local temp directory.
# If the input files change, this output file will need
# to be deleted in order to have the counts recomputed.
#######################################################

all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Get dataset id for PanGene to help simplify queries
dataset_name="MaizeGDB-NAM-Pangene data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "Maize PanGene data set not found in database"
    exit 1;
fi

# Use script to count total number of expected syntelogs
this_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$this_path"
if [ ! -d "temp" ]; then
    mkdir temp
fi

pangene_filename=$(find /db/*/datasets/MaizeGDB-NAM-PanGene/ -maxdepth 1 -name *.tab)
echo "PanGene input file: $orthodb_filename"

# First check total number of syntelogs
echo "Counting expected number of syntelogs from input file..."
outfile="temp/pangene_count.txt"
if [ ! -f "$outfile" ]; then
    echo "(This will take a while)"
    # Can use same script as homologues because works the same way
    ../data_parsing/count_homologues.sh "$pangene_filename" | tee >(tail -n 1 > $outfile)
fi
file_count=$(grep -oE "[0-9]+" "$outfile")

echo "Querying database for total number of PanGene syntelogs..."
dbcount=$(psql ${dbname} -c "select count(id) from syntelog h join datasetssyntelog dh on dh.syntelog=h.id where dh.datasets=${dataset_id}" -t -A)

if [ ! $file_count -eq $dbcount ]; then
    echo "WARNING: expected $file_count syntelogs from input file, but $dbcount PanGene syntelogs in database!"
    all_counts_correct=0
else
    echo "PanGene syntelogs count correct ($dbcount syntelogs)"
fi
echo

# Next check number of PanGene groups
echo "Counting expected number of PanGene groups from input file..."
file_count=$(cut -f 2 "$pangene_filename" | sort | uniq | wc -l)
echo "Querying database for number of PanGene syntelog groups..."
dbcount=$(psql ${dbname} -c"select count(oc.id) from pangenegroup oc join datasetspangenegroup doc on doc.pangenegroup = oc.id where doc.datasets=${dataset_id}" -t -A)
if [ ! $dbcount -eq $file_count ]; then
    echo "WARNING: found $file_count PanGene groups from input file, but $dbcount groups in PanGeneGroup table!"
    all_counts_correct=0
fi

echo "Querying database for number of PanGene groups in Syntelog table..."
dbcount=$(psql ${dbname} -c "select count(distinct(h.pangeneid)) from syntelog h join datasetssyntelog dh on dh.syntelog=h.id where dh.datasets=${dataset_id} and h.pangeneid is not null" -t -A)
file_count=$(cut -f 2 "$pangene_filename" | sort | uniq -c | grep -v ' 1 ' | wc -l)
if [ ! $dbcount -eq $file_count ]; then
    echo "WARNING: Expected $file_count PanGene groups with gene pairs from input file, but $dbcount groups in database!"
    all_counts_correct=0
else
    echo "PanGene groups count correct ($dbcount groups)"
fi
echo

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

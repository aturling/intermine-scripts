#!/bin/bash  

#######################################################
# hgd_ortho_count.sh
#
# Check database for correct number of HGD-Ortho genes
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

# Get dataset id for HGD-Ortho to help simplify queries
dataset_name="HGD-Ortho data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "HGD-Ortho data set not found in database"
    exit 1;
fi

# Use script to count total number of expected homologues
this_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$this_path"
if [ ! -d "temp" ]; then
    mkdir temp
fi

ortho_filenames=$(find /db/*/datasets/HGD-Ortho/ -maxdepth 1 -name *.tab)

total_file_count=0
echo "Counting expected number of homologues from input files..."
for ortho_file in $ortho_filenames; do
    echo "Input file: $ortho_file"
    suffix=$(echo "$ortho_file" | awk -F'/' '{print $6}' | awk -F'_' '{print $1}')
    outfile="temp/hgd_ortho_count_${suffix}.txt"
    if [ ! -f "$outfile" ]; then
        echo "(This will take a while)"
        ../data_parsing/count_homologues.sh "$ortho_file" | tee >(tail -n 1 > $outfile)
    fi
    file_count=$(grep -oE "[0-9]+" "$outfile")
    total_file_count=$((total_file_count + file_count))
done

echo "Querying database for total number of HGD-Ortho homologues..."
dbcount=$(psql ${dbname} -c "select count(id) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id}" -t -A)

if [ ! $total_file_count -eq $dbcount ]; then
    echo "WARNING: expected $total_file_count homologues from input file, but $dbcount HGD-Ortho homologues in database!"
    all_counts_correct=0
else
    echo "HGD-Ortho homologues count correct ($dbcount homologues)"
fi
echo

# Next check number of clusters
total_file_count=0
echo "Counting expected number of clusters from input files..."
for ortho_file in $ortho_filenames; do
    echo "Input file: $ortho_file"
    file_count=$(cut -f 2 "$ortho_file" | sort | uniq | wc -l)
    total_file_count=$((total_file_count + file_count))
done
echo "Querying database for number of HGD-Ortho clusters in Homologue table..."
dbcount1=$(psql ${dbname} -c "select count(distinct(h.clusterid)) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id} and h.clusterid is not null" -t -A)
echo "Querying database for number of HGD-Ortho OrthologueClusters..."
dbcount2=$(psql ${dbname} -c"select count(oc.id) from orthologuecluster oc join datasetsorthologuecluster doc on doc.orthologuecluster = oc.id where doc.datasets=${dataset_id}" -t -A)
if [ ! $dbcount1 -eq $dbcount2 ]; then
    echo "WARNING: found $dbcount clusters in Homologue table, but $dbcount2 clusters in OrthologueCluster table!"
    all_counts_correct=0
fi
if [ ! $dbcount1 -eq $total_file_count ]; then
    echo "WARNING: Expected $total_file_count clusters from input file, but $dbcount1 clusters in database!"
    all_counts_correct=0
else
    echo "HGD-Ortho cluster count correct ($dbcount1 clusters)"
fi
echo

# Next check number of genes
total_file_count=0
echo "Counting expected number of distinct gene IDs from input files..."
for ortho_file in $ortho_filenames; do
    echo "Input file: $ortho_file"
    file_count=$(cut -f 3 "$ortho_file" | sort | uniq | wc -l)
    total_file_count=$((total_file_count + file_count))
done
echo "Querying database for number of HGD-Ortho gene IDs in homologue table..."
dbcount=$(psql ${dbname} -c "select count(distinct(geneid)) from homologue h join datasetshomologue dh on dh.homologue=h.id where dh.datasets=${dataset_id}" -t -A)
if [ ! $total_file_count -eq $dbcount ]; then
    echo "WARNING: Expected $total_file_count genes, but $dbcount genes in Homologue table!"
    all_counts_correct=0
else
    echo "HGD-Ortho gene count correct ($dbcount distinct genes)"
fi

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

#!/bin/bash  

#######################################################
# uniprot_count.sh
#
# Check database for correct number of UniProt proteins.
#######################################################

section_divide="----------------------------------------------------------------"
all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

# Swiss-Prot data set:

# Get dataset id to help simplify queries
dataset_name="Swiss-Prot data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "Data set '$dataset_name' not in database!"
    # Exit early, nothing to do
    exit 1
fi

# Get taxon ID list from filenames
filenames=$(find /db/*/datasets/*ni*rot -maxdepth 1 -type f -name *uniprot*sprot.xml)

# Iterate through input file list
for filename in $filenames; do
    # Get taxon ID from filename
    taxon_id=$(echo "$filename" | grep -oE "[0-9][0-9][0-9][0-9]+")
    echo "Checking UniProt (Swiss-Prot) proteins for organism with taxon id $taxon_id"

    # Get number of UniProt proteins (by id) in database for this organism
    echo "Querying database for proteins..."
    dbcount=$(psql ${dbname} -c "select count(p.id) from protein p join organism o on o.id=p.organismid join bioentitiesdatasets bed on bed.bioentities=p.id where bed.datasets=${dataset_id} and o.taxonid='${taxon_id}'" -t -A)
    # Get number of proteins in file for this organism
    file_count1=$(grep "<sequence length" "$filename" | wc -l)
    file_count2=$(grep "<isoform>" "$filename" | wc -l)
    file_count=$((file_count1 + file_count2))

    if [ ! $file_count -eq $dbcount ]; then
        echo "WARNING: $file_count proteins in $filename, but $dbcount proteins in database!"
        all_counts_correct=0
    else
        echo "Protein count correct ($dbcount proteins)"
    fi
done
echo

# TrEMBL data set:

# Get dataset id to help simplify queries
dataset_name="TrEMBL data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

# Get taxon ID list from filenames
filenames=$(find /db/*/datasets/*ni*rot -maxdepth 1 -type f -name *uniprot*trembl.xml)

# Iterate through input file list
for filename in $filenames; do
    # Get taxon ID from filename
    taxon_id=$(echo "$filename" | grep -oE "[0-9][0-9][0-9][0-9]+")
    echo "Checking UniProt (TrEMBL) proteins for organism with taxon id $taxon_id"

    # Get number of UniProt proteins (by id) in database for this organism
    echo "Querying database for proteins..."
    dbcount=$(psql ${dbname} -c "select count(p.id) from protein p join organism o on o.id=p.organismid join bioentitiesdatasets bed on bed.bioentities=p.id where bed.datasets=${dataset_id} and o.taxonid='${taxon_id}'" -t -A)
    # Get number of proteins in file for this organism
    file_count1=$(grep "<sequence length" "$filename" | wc -l)
    file_count2=$(grep "<isoform>" "$filename" | wc -l)
    file_count=$((file_count1 + file_count2))

    if [ ! $file_count -eq $dbcount ]; then
        echo "WARNING: $file_count proteins in $filename, but $dbcount proteins in database!"
        all_counts_correct=0
    else
        echo "Protein count correct ($dbcount proteins)"
    fi
done

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo


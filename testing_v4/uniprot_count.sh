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

echo "Database name is ${dbname}"
echo

# Begin checking Swiss-Prot data set:

# Get dataset id to help simplify queries
dataset_name="Swiss-Prot data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

# Get taxon ID list from filenames
sprot_files=$(find /db/*/datasets/*ni*rot -maxdepth 1 -type f -name *uniprot*sprot.xml)

# Iterate through input file list
for sprot_file in $sprot_files; do
    # Get taxon ID from filename
    taxon_id=$(echo "$sprot_file" | grep -oE "[0-9][0-9][0-9][0-9]+")
    echo "Checking UniProt (Swiss-Prot) proteins for organism with taxon id $taxon_id"

    # Get number of UniProt proteins (by id) in database for this organism
    echo "Querying database for proteins..."
    dbcount=$(psql ${dbname} -c "select count(p.id) from protein p join organism o on o.id=p.organismid join bioentitiesdatasets bed on bed.bioentities=p.id where bed.datasets=${dataset_id} and o.taxonid='${taxon_id}'" -t -A)
    # Get number of proteins in file for this organism
    file_count1=$(grep "<sequence length" "$sprot_file" | wc -l)
    file_count2=$(grep "<isoform>" "$sprot_file" | wc -l)
    file_count=$((file_count1 + file_count2))

    if [ ! $file_count -eq $dbcount ]; then
        echo "WARNING: $file_count proteins in $sprot_file, but $dbcount proteins in database!"
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


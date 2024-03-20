#!/bin/bash  

#######################################################
# ensembl_compara_count.sh
#
# Check database for correct number of homologues from
# Ensembl Compara data set.
#######################################################

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Check if data set exists
subdir="EnsemblCompara"
ensembl_comp_dir=$(find /db/*/datasets -maxdepth 1 -type d -name "$subdir")
if [ -z $ensembl_comp_dir ]; then
    # Check for biomart
    subdir="ensembl-plant-biomart/homologues"
    numfiles=$(ls /db/*/datasets/$subdir 2>/dev/null | wc -l)
    if [ ! "$numfiles" -gt 0 ]; then
        echo "Ensembl Compara data set does not exist"
        exit 1
    fi
fi

all_counts_correct=1

# Get list of taxon IDs from input files
taxon_ids=$(find /db/*/datasets/${subdir} -maxdepth 1 -type f -printf '%f\n' | awk -F'_' '{printf "%s\\n\n%s\\n\n", $1, $2}' | sed 's/\\n//g' | sort | uniq)

# Get number of homologues from Ensembl Compara per taxon ID
echo "Querying database for Ensembl Compara homologues..."
dataset_name="Ensembl Compara data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "Data set '$dataset_name' not in database!"
    # Exit early, nothing to do
    exit 1
fi

for taxon_id in $taxon_ids; do
    # Get number of homologues for this organism in database
    dbcount=$(psql ${dbname} -c "select count(h.id) from homologue h join datasetshomologue dh on dh.homologue=h.id join gene g on g.id=h.geneid join organism o on o.id=g.organismid where dh.datasets='${dataset_id}' and o.taxonid='${taxon_id}'" -t -A)
    # Get number of homologues for this organism by counting lines of files with taxon id in filename (first before underscore)
    # Every valid line has "ortholog" or "paralog" in last column so grep on that to exclude invalid/empty lines
    file_count=$(grep -E '[ortholog|paralog]' /db/*/datasets/${subdir}/${taxon_id}* | wc -l | grep total | awk '{print $1}')
    if [ -z $file_count ]; then
        file_count=$(grep -E '[ortholog|paralog]' /db/*/datasets/${subdir}/${taxon_id}* | wc -l)
    fi
    if [ $dbcount -eq $file_count ]; then
        echo "Homologue count correct for organism with taxon id $taxon_id ($file_count homologues)"
    else
        echo "WARNING: database has $dbcount homologues for organism with taxon id $taxon_id, files have $file_count homologues!"
        all_counts_correct=0
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

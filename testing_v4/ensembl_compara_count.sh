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
ensembl_comp_dir=$(find /db/*/datasets -maxdepth 1 -type d -name EnsemblCompara)
if [ -z $ensembl_comp_dir ]; then
    echo "Ensembl Compara data set does not exist"
    exit 1
fi

all_counts_correct=1

# Get list of taxon IDs from input files
taxon_ids=$(find /db/*/datasets/EnsemblCompara -type f -printf '%f\n' | awk -F'_' '{printf "%s\\n\n%s\\n\n", $1, $2}' | sed 's/\\n//g' | sort | uniq)

# Get number of homologues from Ensembl Compara per taxon ID
echo "Querying database for Ensembl Compara homologues..."
dataset_name="Ensembl Compara data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)


for taxon_id in $taxon_ids; do
    dbcount=$(psql ${dbname} -c "select count(h.id) from homologue h join datasetshomologue dh on dh.homologue=h.id join gene g on g.id=h.geneid join organism o on o.id=g.organismid where dh.datasets='${dataset_id}' and o.taxonid='${taxon_id}'" -t -A)
    file_count=$(wc -l /db/*/datasets/EnsemblCompara/*${taxon_id}* | grep total | awk '{print $1}')
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

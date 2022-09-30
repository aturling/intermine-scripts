#!/bin/bash  

#######################################################
# reactome_count.sh
#
# Check database for correct number of Reactome 
# pathways.
#######################################################

section_divide="----------------------------------------------------------------"
all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Requires that entrez-organism loaded first
nullcount=$(psql ${dbname} -c "select count(*) from organism where name is null" -t -A)
if [ "$nullcount" -gt 0 ]; then
    echo "Entrez-organism source needs to be loaded before running this test!"
    # Exit early, nothing to do
    exit 1
fi

# Get dataset id for Reactome to help simplify queries
dataset_name="Reactome pathways data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "Data set '$dataset_name' not in database!"
    # Exit early, nothing to do
    exit 1
fi

# Get organism taxon id from project.xml
orgs=$(grep "reactome.organisms" /db/*/intermine/*/project.xml | grep -oE "value=.*" | awk -F'"' '{print $2}' | tr ' ' '\n')
# Iterate through taxon id list
for org in $orgs; do
    # Get org name from taxon id in database
    name=$(psql ${dbname} -c "select o.name from organism o where o.taxonid='${org}'" -t -A)
    # Get org id from taxon id in database
    org_id=$(psql ${dbname} -c "select o.id from organism o where o.taxonid='${org}'" -t -A)
    echo "Checking pathways for organism: $name with taxon id $org"
    # Get pathway count for organism from file
    filecount=$(grep -P "\t${name}" /db/*/datasets/Reactome/*.txt | cut -f2 | sort | uniq | wc -l)
    # Special case: if count is zero, might be that organism name is slightly different in file
    # Check how many parts and just use first and last
    if [ "$filecount" -eq 0 ]; then
        name_parts=$(echo "$name" | tr ' ' '\n' | wc -l)
        if [ "$name_parts" -gt 2 ]; then
            first=$(echo "$name" | tr ' ' '\n' | head -n 1)
            last=$(echo "$name" | tr ' ' '\n' | tail -n 1)
            name="$first $last"
            echo "None found in file, searching on $name instead"
            filecount=$(grep -P "\t${name}" /db/*/datasets/Reactome/*.txt | cut -f2 | sort | uniq | wc -l)
        fi
    fi
    # Get pathway count from database
    dbcount=$(psql ${dbname} -c "select count(*) from pathway p join datasetspathway dp on dp.pathway=p.id join dataset d on d.id=dp.datasets where d.id=${dataset_id} and organismid=${org_id}" -t -A)
    if [ ! "$filecount" -eq "$dbcount" ]; then
        echo "WARNING: $filecount pathways in Reactome data file, but $dbcount in database!"
        all_counts_correct=0
    else
        echo "Pathways count correct ($dbcount pathways)"
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


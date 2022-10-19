#!/bin/bash  

#######################################################
# faang_expression_count.sh
#
# Check database for correct number of expression items
#######################################################

section_divide="----------------------------------------------------------------"
all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Get dataset id for FAANG gene expression to help simplify queries
dataset_name="Gene RNASeq expression data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "Data set '$dataset_name' not in database!"
    # Exit early, nothing to do
    exit 1
fi

# Iterate over organisms and sources:
data_subdir="gene_expression"
orgs=$(find /db/*/datasets/${data_subdir}/ -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort)
for org in $orgs; do
    # Get org id in database
    org_name=$(echo "${org}" | sed 's/_/ /g')
    org_id=$(psql ${dbname} -c "select o.id from organism o where lower(o.name)='${org_name}'" -t -A)
    if [ -z $org_id ]; then
        echo "WARNING: organism $org_name not in database!"
        echo
        continue
    fi

    sources=$(find /db/*/datasets/${data_subdir}/${org}/ -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort)
    for genesource in $sources; do
        # Database count:
        dbcount=$(psql ${dbname} -c "select count(g.id) from gene g join bioentitiesdatasets bed on bed.bioentities=g.id join dataset d on d.id=bed.datasets where g.organismid=${org_id} and g.source='${genesource}' and d.id=${dataset_id}" -t -A)
        # File count:
        # First row is header, begins with "Gene"
        filecount=$(cut -f1 /db/*/datasets/${data_subdir}/${org}/${genesource}/*.tab | grep -v Gene | sort | uniq | wc -l)

        if [ ! "$dbcount" -eq "$filecount" ]; then
            echo "WARNING: $dbcount $genesource genes for $org_name in database, but $filecount in input file!"
            all_counts_correct=0
        else
            echo "Gene count correct for $genesource $org_name genes ($dbcount genes)"
        fi
    done
done

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

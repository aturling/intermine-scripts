#!/bin/bash  

#######################################################
# custom_gene_info_count.sh
#
# Check database for correct number of genes from custom
# gene info data set (reference species).
#######################################################

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Check that data set exists
custom_gene_dir=$(find /db/*/datasets -maxdepth 1 -type d -name custom-gene-info)
if [ -z $custom_gene_dir ]; then
    echo "Custom gene info dataset does not exist"
    exit 1
fi

all_counts_correct=1
# Get source names from directory structure
sources=$(find /db/*/datasets/custom-gene-info/ -mindepth 1 -maxdepth 1 -type d | awk -F'/' '{print $(NF)}')

echo "Checking custom gene info gene IDs..."
for source in $sources; do
    echo "Source: $source" 
    # Get file list
    files=$(find /db/*/datasets/custom-gene-info/${source}/ -not -path '*/old/*' -type f -name *.tab)
    for file in $files; do
        taxon_id=$(echo "$file" | grep -oE "[0-9][0-9][0-9][0-9]+")
        # Check counts
        echo "Checking gene counts for organism with taxon ID $taxon_id..."
        file_count=$(cut -f 1 "$file" | wc -l)
        echo "$file_count"
        # Assumes data set name is of the form "<source> genes for <species>" or similar
        dbcount=$(psql ${dbname} -c "select count(g.id) from gene g join organism o on o.id=g.organismid join bioentitiesdatasets bed on bed.bioentities=g.id join dataset d on d.id=bed.datasets where o.taxonid='${taxon_id}' and g.source='${source}' and d.name like '%genes for%';" -t -A)
        if [ $file_count -eq $dbcount ]; then
            echo "Gene count correct ($dbcount genes)"
        else
            echo "WARNING: database has $dbcount $source genes with taxon ID $taxon_id, but input file has $file_count!"
            all_counts_correct=0
        fi
        # Spot check symbol and description for first gene
        first_gene_id=$(cut -f 1 "$file" | head -n 1)
        first_symbol=$(cut -f 3 "$file" | head -n 1)
        first_desc=$(cut -f 4 "$file" | head -n 1)
        echo "Checking representative gene $first_gene_id symbol and description fields..."
        dbsymbol=$(psql ${dbname} -c "select symbol from gene where primaryidentifier='${first_gene_id}'" -t -A)
        dbdesc=$(psql ${dbname} -c "select description from gene where primaryidentifier='${first_gene_id}'" -t -A)
        if [ "$first_symbol" != "$dbsymbol" ] ; then
            echo "WARNING: symbol $first_symbol not set in database!"
        fi
        if [ "$first_desc" != "$dbdesc" ] ; then
            echo "WARNING: description $first_desc not set in database!"
        fi
    done
    echo
done

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

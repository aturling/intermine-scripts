#!/bin/bash  

#######################################################
# pubmed_gene_test.sh
#
# Check database for correct loading of PubMed Gene
# data source.
# Note: can't check counts for this source, so this script
# spot checks different genes+publications to check that
# they were loaded into the database correctly.
#######################################################

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

all_loads_correct=1
# Check that directory exists
srcdir=$(find /db/*/datasets -maxdepth 1 -type d -name "*pubmed-gene")
if [ -z "$srcdir" ]; then
    echo "No PubMed gene input files found"
    exit 1
fi

# Iterate over files
files=$(find /db/*/datasets/*pubmed-gene/ -maxdepth 1 -type f)
for pubmed_file in $files; do
    # Get list of taxon IDs to check
    taxon_ids=$(cut -f 1 $pubmed_file | sort -n | uniq)   
    echo "Checking taxon ids from file $pubmed_file..."
    for taxon_id in $taxon_ids; do
        # Check one line per taxon id
        one_line=$(grep -P "^${taxon_id}\t" $pubmed_file | head -n 1)
        gene_id=$(echo "$one_line" | cut -f 2)
        pubmed_id=$(echo "$one_line" | cut -f 3)
        echo "Querying database for gene id $gene_id, taxon id $taxon_id, PubMed id ${pubmed_id}..."
        org_id=$(psql ${dbname} -c "select id from organism where taxonid='${taxon_id}'" -t -A)
        if [ -z $org_id ]; then
            echo "WARNING: organism with taxon id $taxon_id not in database!"
            continue
        fi
        dbrow=$(psql ${dbname} -c "select g.id from sequencefeature g join entitiespublications ep on ep.entities=g.id join publication p on ep.publications=p.id where g.primaryidentifier='${gene_id}' and g.organismid=${org_id} and p.pubmedid='${pubmed_id}'" -t -A)
        if [ -z "$dbrow" ]; then
            echo "WARNING: expected gene/publication not in database!"
            all_loads_correct=0
        else
            echo "Gene/publication found in database"
        fi
    done
    echo
done

echo
echo "SUMMARY:"
if [ $all_loads_correct -eq 0 ]; then
    echo "Some publications/genes were not loaded into the database correctly!"
else
    echo "All publications and genes that were tested loaded correctly."
fi
echo

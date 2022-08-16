#!/bin/bash  

#######################################################
# gff_count.sh
#
# Check database for correct number of entities loaded
# from gff files (genes, exons, transcripts, etc.)
#
# TODO: add pseudogenes
#######################################################

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

all_counts_correct=1

sources=("RefSeq" "Ensembl" "MaizeGDB" "Genbank")
echo "Checking gff counts..."
for source in "${sources[@]}" ; do
    echo "Source: $source"
    # Iterate over all organisms/assemblies
    files=$(find /db/*/datasets/${source}/annotation*/*/*/genes -type f -name *.gff3 2>/dev/null)
    for file in $files; do
        org_name=$(echo "${file}" | awk -F'/' '{print $7}' | sed 's/_/ /g')
        assembly=$(echo "${file}" | awk -F'/' '{print $8}')
        echo "Checking $source gff for $org_name (assembly: $assembly)..."
    
        # Get org id in database
        org_id=$(psql ${dbname} -c "select o.id from organism o where lower(o.name)='${org_name}'" -t -A)
        if [ -z $org_id ]; then
            # Try using assembly version instead
            org_id=$(psql ${dbname} -c "select o.id from chromosome c join organism o on o.id=c.organismid where c.assembly='${assembly}' limit 1" -t -A)
        fi
        if [ -z $org_id ]; then
            # If still can't find it, skip to next organism
            echo "WARNING: organism $org_name not in database!"
            echo
            continue
        fi

        # Get all possible class names (transcripts, genes, etc.)
        echo "Getting all class names in input file..."
        classes=$(cat /db/*/datasets/${source}/annotation*/*/${assembly}/genes/*.gff3 | grep -v "#" | cut -f 3 | sort | uniq)
        echo $classes
        class_count_correct=1
        for class in $classes; do
            # Get database table name from class
            tablename=$(echo "$class" | sed 's/[^ _]*/\u&/g' | sed 's/_//g')
            # Count in database
            dbcount=0
            # Special case: gene
            if [ "$class" == "gene" ]; then
                dbcount=$(psql ${dbname} -c "select count(g.id) from gene g join bioentitiesdatasets bed on bed.bioentities=g.id join dataset d on d.id=bed.datasets where g.organismid=${org_id} and g.source='${source}' and d.name like '%${source} gene set%'" -t -A)
            else
                dbcount=$(psql ${dbname} -c "select count(t.id) from $tablename t where t.organismid=${org_id} and t.source='${source}' and t.class='org.intermine.model.bio.${tablename}'" -t -A)
            fi
            filecount=$(cat /db/*/datasets/${source}/annotation*/*/${assembly}/genes/*.gff3 | grep -v "#" | cut -f 3 | grep -E "^${class}" | wc -l)
            if [ ! $dbcount -eq $filecount ]; then
                echo "WARNING: $dbcount ${class}s in database, but $filecount in input file!"
                class_count_correct=0
                all_counts_correct=0
            fi
         done
         if [ ! $class_count_correct -eq 0 ]; then
             echo "Counts correct for all class names"
         fi
         echo
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

#!/bin/bash  

#######################################################
# faang_gff_count.sh
#
# Check database for correct number of entities loaded
# from faang gff files.
#######################################################

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

all_counts_correct=1

echo "Checking FAANG gff counts..."
# Iterate over all organisms/assemblies
orgs=$(find /db/*/datasets/FAANG-gff -maxdepth 1 -mindepth 1 -type d | awk -F'/' '{print $(NF)}' | sort)
for org in $orgs; do
    org_name=$(echo "${org}" | sed 's/_/ /g')

    # Get org id in database
    org_id=$(psql ${dbname} -c "select o.id from organism o where lower(o.name)='${org_name}'" -t -A)
    if [ -z $org_id ]; then
       # Try using assembly version instead
       org_id=$(psql ${dbname} -c "select o.id from chromosome c join organism o on o.id=c.organismid where c.assembly='${assembly}' limit 1" -t -A)
    fi

    assemblies=$(find /db/*/datasets/FAANG-gff/${org} -maxdepth 1 -mindepth 1 -type d | awk -F'/' '{print $(NF)}' | sort)
    for assembly in $assemblies; do
        echo "Checking gff for ${org_name^} (assembly: $assembly)..."
    
        # Get all possible class names (transcripts, genes, etc.)
        echo "Getting all class names in input file..."
        classes=$(cat /db/*/datasets/FAANG-gff/${org}/${assembly}/*.gff3 | grep -v "#" | cut -f 3 | sort | uniq)
        echo $classes
        class_count_correct=1
        for class in $classes; do
            # Get database table name from class
            tablename=$(echo "$class" | sed 's/[^ _]*/\u&/g' | sed 's/_//g')
            # Count in database
            dbcount=$(psql ${dbname} -c "select count(t.id) from $tablename t where t.organismid=${org_id} and t.class='org.intermine.model.bio.${tablename}'" -t -A)
            filecount=$(cat /db/*/datasets/FAANG-gff/*/${assembly}/*.gff3 | grep -v "#" | cut -f 3 | grep -E "^${class}" | wc -l)
            if [ ! $dbcount -eq $filecount ]; then
                echo "WARNING: $dbcount ${class}s in database, but $filecount in input file!"
                class_count_correct=0
                all_counts_correct=0
            fi
        done
        if [ ! $class_count_correct -eq 0 ]; then
            echo "Counts correct for all class names"
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

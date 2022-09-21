#!/bin/bash  

#######################################################
# qtl_gff_count.sh
#
# Check database for correct number of entities loaded
# from QTL gff files.
#######################################################

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

all_counts_correct=1

echo "Checking QTL gff counts..."
# Iterate over all organisms/assemblies
orgs=$(find /db/*/datasets/QTL -maxdepth 1 -mindepth 1 -type d | awk -F'/' '{print $(NF)}' | sort)
for org in $orgs; do
    org_name=$(echo "${org}" | sed 's/_/ /g')

    # Get org id in database
    org_id=$(psql ${dbname} -c "select o.id from organism o where lower(o.name)='${org_name}'" -t -A)
    if [ -z $org_id ]; then
       # Try using assembly version instead
       org_id=$(psql ${dbname} -c "select o.id from chromosome c join organism o on o.id=c.organismid where c.assembly='${assembly}' limit 1" -t -A)
    fi

    assemblies=$(find /db/*/datasets/QTL/${org} -maxdepth 1 -mindepth 1 -type d | awk -F'/' '{print $(NF)}' | sort)
    for assembly in $assemblies; do
        echo "Checking gff for ${org_name^} (assembly: $assembly)..."
    
        qtl_count_correct=1
        # Count in database
        dbcount=$(psql ${dbname} -c "select count(t.id) from qtl t where t.organismid=${org_id}" -t -A)
        filecount=$(cat /db/*/datasets/QTL/${org}/${assembly}/*.gff3 | grep -v "#" | wc -l)
        if [ ! $dbcount -eq $filecount ]; then
            echo "WARNING: $dbcount QTLs in database, but $filecount in input file!"
            qtl_count_correct=0
            all_counts_correct=0
        fi
        if [ ! $qtl_count_correct -eq 0 ]; then
            echo "QTL count correct"
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

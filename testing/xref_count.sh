#!/bin/bash  

#######################################################
# xref_count.sh
#
# Count number of xrefs from xrefs source
#######################################################

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

all_counts_correct=1

# Iterate over all organisms/assemblies
orgs=$(find /db/*/datasets/xref/gene -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null)
for org in $orgs; do
    org_name=$(echo "${org}" | sed 's/_/ /g')
    echo "Checking xrefs for $org_name"    
    # Get org id in database
    org_id=$(psql ${dbname} -c "select o.id from organism o where lower(o.name)='${org_name}'" -t -A)
    if [ -z $org_id ]; then
        echo "WARNING: organism $org_name not in database!"
        echo
        continue
    fi
    # Count from files
    file_count=$(cat /db/*/datasets/xref/gene/${org}/*/* | wc -l)
    # Count in database
    dbcount=$(psql ${dbname} -c "select count(g.id) from crossreference c join gene g on g.id=c.subjectid where organismid=${org_id} and c.targetid is not null" -t -A)
    if [ ! "$dbcount" -eq "$file_count" ]; then
        echo "WARNING: $dbcount xrefs in database, but $file_count in input file!"
        all_counts_correct=0
    else
        echo "Counts correct ($dbcount xrefs)"
    fi

    # Also check for extra xrefs
    dbcount=$(psql ${dbname} -c "select count(g.id) from crossreference c join gene g on g.id=c.subjectid where organismid=${org_id} and c.targetid is null" -t -A)
    if [ ! "$dbcount" -eq 0 ]; then
        echo "NOTE: $dbcount xrefs in database not from xrefs source for this organism"
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

#!/bin/bash  

#######################################################
# faang_metadata_count.sh
#
# Check database for correct number of entities loaded
# from faang metadata files.
#######################################################

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

all_counts_correct=1

echo "Checking BioProjects..."

# Check number of bioprojects in database
# Each line in file is unique bioproject so count number of lines (minus header)
filecount=$(tail -n +2 /db/*/datasets/FAANG-bioproject/bioproject.txt | wc -l)
dbcount=$(psql ${dbname} -c "select count(id) from bioproject" -t -A)
if [ ! "$dbcount" -eq "$filecount" ]; then
    echo "WARNING: $dbcount BioProjects in database, but $filecount in input file!"
    all_counts_correct=0
else
    echo "BioProject count correct ($dbcount BioProjects)"
fi

# Check that organism ref was set
null_orgs=$(psql ${dbname} -c "select count(id) from bioproject where organismid is null" -t -A)
if [ ! $null_orgs -eq 0 ]; then
    echo "WARNING: $null_orgs BioProjects with no organism ref in database!"
else
    echo "BioProject organism refs set correctly"
fi

# Check publications count
filecount=$(cut -f7 /db/*/datasets/FAANG-bioproject/bioproject.txt | grep -v PMID | grep -v '-' | sort | uniq | wc -l)
dbcount=$(psql ${dbname} -c "select count(distinct(publications)) from bioprojectpublications" -t -A)
if [ ! "$dbcount" -eq "$filecount" ]; then
    echo "WARNING: $dbcount BioProject publication refs in database, but $filecount in input file!"
    all_counts_correct=0
else
    echo "BioProject publication ref count correct ($dbcount Publications)"
fi

#TODO: biosamples, analyses, experiments

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

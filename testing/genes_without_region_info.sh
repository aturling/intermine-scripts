#!/bin/bash  

#######################################################
# genes_without_region_info.sh
#
# Check number of genes that were loaded with no region
# info (no chr/location) but did include gene source.
# Displays query result for info only.
#######################################################

section_divide="----------------------------------------------------------------"
all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Run query and display results
echo "Running query for genes with source but no region info..."
psql ${dbname} -c "select count(g.primaryidentifier) as genecount, d.name from gene g join bioentitiesdatasets bd on bd.bioentities=g.id join dataset d on bd.datasets=d.id where g.source is not null and g.length is null group by d.name order by genecount desc"

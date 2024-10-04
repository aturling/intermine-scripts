#!/bin/bash  

#######################################################
# transcripts_without_chr_info.sh
#
# Check for transcripts with no chromosome info.
# May indicate merge issue with data sets.
# Displays query result for info only.
#######################################################

section_divide="----------------------------------------------------------------"
all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Run query and display results
echo "Running query for transcripts with no chromosome info..."
psql ${dbname} -c "select count(sf.primaryidentifier) from sequencefeature sf join bioentitiesdatasets bd on bd.bioentities=sf.id join dataset d on d.id=bd.datasets join organism o on o.id=sf.organismid join soterm so on so.id=sf.sequenceontologytermid where sf.source is not null and so.name='transcript' and sf.chromosomeid is null;"

if [ ! -z $1 ]; then
  psql ${dbname} -c "select sf.primaryidentifier as sequencefeature_id,sf.source,o.name as organism_name,so.name as soterm_name, d.name as dataset_name from sequencefeature sf join bioentitiesdatasets bd on bd.bioentities=sf.id join dataset d on d.id=bd.datasets join organism o on o.id=sf.organismid join soterm so on so.id=sf.sequenceontologytermid where sf.source is not null and so.name='transcript' and sf.chromosomeid is null;"
fi

scriptname=`basename "$0"`
echo "To see actual transcripts, run this script again with 'true' as a command line parameter:"
echo "./$scriptname true"

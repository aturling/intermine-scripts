#!/bin/bash  

#######################################################
# biogrid_count.sh
#
# Check database for correct number of BioGRID items.
#######################################################

section_divide="----------------------------------------------------------------"
all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Each InteractionExperiment has one pub reference, so count number of distinct PubMed ids across
# BioGRID files
# First check that every InteractionExperiment has a pub reference:
no_pub_ref_count=$(psql ${dbname} -c "select count(ie.id) from interactionexperiment ie where ie.publicationid is null" -t -A)
if [ ! "$no_pub_ref_count" -eq 0 ]; then
    echo "WARNING: $no_pub_ref_count InteractionExperiments with no referenced Publication!"
    all_counts_correct=0
else
    echo "No null pub refs, checking InteractionExperiment count..."
    # Next count number of publication references
    # Exclude first 23 lines because first overall pub doesn't get loaded
    num_pubs=$(tail -n +23 /db/*/datasets/BioGRID/* | grep 'db="pubmed"' | grep -oE 'id="[0-9]+"' | sort | uniq | wc -l)
    # Count number of interactionexperiments; should be same number as long as each one references a pub
    num_ies=$(psql ${dbname} -c "select count(ie.id) from interactionexperiment ie" -t -A)
    if [ ! "$num_ies" -eq "$num_pubs" ]; then
        echo "WARNING: $num_pubs InteractionExperiments in files, but $num_ies in database!"
        all_counts_correct=0
    else
        echo "Number of InteractionExperiments correct ($num_ies InteractionExperiments)"
    fi
fi

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo


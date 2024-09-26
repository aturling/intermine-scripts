#!/bin/bash  

#######################################################
# gpluse_reactions_count.sh
#
# Check database for correct number of GplusE genes and 
# reactions.
#######################################################

# Function to get organism taxon id from *_reactions.tab file
# Input args:
#   (1) *_reactions.tab filename
get_taxon_id_from_reaction_file () {
    local reactions_filename=$1
    local taxonid=$(echo "$reactions_filename" | grep -oE "\w+_reactions" | awk -F'_' '{print $1}')
    echo $taxonid
}

section_divide="----------------------------------------------------------------"
all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Get dataset id for GplusE reactions to help simplify queries
dataset_name="GplusE reactions data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "Data set '$dataset_name' not in database!"
    # Exit early, nothing to do
    exit 1
fi

# Get *_reactions.tab input filenames
reaction_files=$(find /db/*/datasets/GPLUSE/reactions -maxdepth 1 -type f -name *reactions.tab)

# Iterate through GplusE reactions input file list
for reaction_file in $reaction_files; do
    # Get taxon id from filename
    taxonid=$(get_taxon_id_from_reaction_file $reaction_file)
    echo "Checking GplusE genes and reactions for organism with taxon id $taxonid"

    # Get number of reactions in database for this organism
    echo "Querying database for reactions..."
    dbcount=$(psql ${dbname} -c "select count(distinct(r.id)) from reaction r join genesreactions gr on gr.reactions=r.id join gene g on gr.genes=g.id join organism o on o.id=g.organismid join datasetsreaction dr on dr.reaction=r.id where dr.datasets=${dataset_id} and o.taxonid='${taxonid}'" -t -A)
    reactions_count=$(cut -f2 ${reaction_file} | tr ' ' '\n' | sort | uniq | wc -l)
    # Reaction count from file and database should agree
    if [ ! $reactions_count -eq $dbcount ]; then
        echo "WARNING: $reactions_count reactions in ${taxonid}_reactions.tab, but $dbcount reactions in database!"
        all_counts_correct=0
    else
        echo "Reactions count correct ($dbcount reactions)"
    fi

    # Query the database for genes and reactions per organism (from gene.reactions collection)
    echo "Querying database for genes and reactions collections..."
    dbcount=$(psql ${dbname} -c "select count(r.identifier) from gene g join organism o on o.id=g.organismid join genesreactions gr on gr.genes=g.id join reaction r on r.id=gr.reactions join datasetsreaction dr on dr.reaction=r.id where dr.datasets=${dataset_id} and o.taxonid='${taxonid}'" -t -A)
    reactions_count=$(cut -f2 ${reaction_file} | tr ' ' '\n' | wc -l)
    if [ ! $reactions_count -eq $dbcount ]; then
        echo "WARNING: $reactions_count genes and reactions in ${taxonid}_reactions.tab, but $dbcount in database!"
        all_counts_correct=0
    else
        echo "Genes and reactions count correct ($reactions_count total)"
    fi

    # Query the database for number of genes with reactions per organism
    dbcount=$(psql ${dbname} -c "select count(distinct(g.primaryidentifier)) from gene g join organism o on o.id=g.organismid join genesreactions gr on gr.genes=g.id join reaction r on r.id=gr.reactions join datasetsreaction dr on dr.reaction=r.id where dr.datasets=${dataset_id} and o.taxonid='${taxonid}'" -t -A)
    reactions_count=$(wc -l $reaction_file | awk '{print $1}')
    if [ ! $reactions_count -eq $dbcount ]; then
        echo "WARNING: $reactions_count genes in ${taxonid}_reactions.tab, but $dbcount in database!"
        all_counts_correct=0
    else
        echo "Genes count correct ($reactions_count total)"
    fi
    echo "$section_divide"
done

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo


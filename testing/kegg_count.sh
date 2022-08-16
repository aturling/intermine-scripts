#!/bin/bash  

#######################################################
# kegg_count.sh
#
# Check database for correct number of KEGG genes and
# pathways.
#######################################################

# Function to get organism abbreviation from *_gene_map.tab file
# Input args:
#   (1) *_gene_map.tab filename
get_abbr_from_gene_map_file () {
    local gene_map_filename=$1
    local abbr=$(echo "$gene_map_file" | grep -oE "\w+_gene_map" | awk -F'_' '{print $1}')
    echo $abbr
}

# Function to get organism taxon id from its abbreviation
# (e.g., 9606 for hsa)
# Input args:
#   (1) organism abbreviation (e.g., hsa for homo sapiens)
get_taxon_id_from_abbr () {
    local abbr=$1
    local taxon_id=$(grep -E "${abbr}[0-9]+" /db/*/datasets/KEGG_genes/map_title.tab | head -n 1 | cut -f 1)
    echo $taxon_id
}

section_divide="----------------------------------------------------------------"
all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Get dataset id for KEGG to help simplify queries
dataset_name="KEGG pathways data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "ERROR: Data set '$dataset_name' not in database!"
    # Exit early, nothing to do
    exit 1
fi

# Get *_gene_map.tab input filenames
kegg_gene_map_files=$(find /db/*/datasets/KEGG_genes -maxdepth 1 -type f -name *map.tab)

# Iterate through KEGG input file list
for gene_map_file in $kegg_gene_map_files; do
    # Get abbreviation from filename
    abbr=$(get_abbr_from_gene_map_file $gene_map_file)
    # Get taxon id for organism from its abbreviation
    taxon_id=$(get_taxon_id_from_abbr $abbr)
    echo "Checking KEGG genes and pathways for organism with taxon id $taxon_id and abbreviation $abbr"

    # Get number of pathways in database for this organism
    echo "Querying database for pathways..."
    dbcount=$(psql ${dbname} -c "select count(p.id) from pathway p join organism o on o.id=p.organismid join datasetspathway dp on dp.pathway=p.id where dp.datasets=${dataset_id} and o.taxonid='${taxon_id}'" -t -A)
    # Get number of pathways in map_title.tab file for this organism
    map_title_count=$(grep $taxon_id /db/*/datasets/KEGG_genes/map_title.tab | wc -l)
    gene_map_count=$(grep -oE "${abbr}[0-9]+" ${gene_map_file} | sort | uniq | wc -l)
    # Pathway count from map_title.tab and abbr_gene_map.tab should agree
    if [ ! $gene_map_count -eq $map_title_count ]; then
        echo "WARNING: $map_title_count pathways in map_title.tab, but $gene_map_count pathways in ${abbr}_gene_map.tab!"
        all_counts_correct=0
    fi
    if [ ! $gene_map_count -eq $dbcount ]; then
        echo "WARNING: $gene_map_count pathways in ${abbr}_gene_map.tab, but $dbcount pathways in database!"
        all_counts_correct=0
    else
        echo "Pathway count correct ($gene_map_count pathways)"
    fi

    # Query the database for genes and pathways per organism (from gene.pathways collection)
    echo "Querying database for genes and pathways collections..."
    dbcount=$(psql ${dbname} -c "select count(p.identifier) from gene g join organism o on o.id=g.organismid join genespathways gp on gp.genes=g.id join pathway p on p.id=gp.pathways join datasetspathway dp on dp.pathway=p.id where dp.datasets=${dataset_id} and o.taxonid='${taxon_id}'" -t -A)
    gene_map_count=$(grep -o $abbr $gene_map_file | wc -l)
    if [ ! $gene_map_count -eq $dbcount ]; then
        echo "WARNING: $gene_map_count genes and pathways in ${abbr}_gene_map.tab, but $dbcount in database!"
        all_counts_correct=0
    else
        echo "Genes and pathways count correct ($gene_map_count total)"
    fi

    # Query the database for number of genes with pathways per organism
    dbcount=$(psql ${dbname} -c "select count(distinct(g.primaryidentifier)) from gene g join organism o on o.id=g.organismid join genespathways gp on gp.genes=g.id join pathway p on p.id=gp.pathways join datasetspathway dp on dp.pathway=p.id where dp.datasets=${dataset_id} and o.taxonid='${taxon_id}'" -t -A)
    gene_map_count=$(wc -l $gene_map_file | awk '{print $1}')
    if [ ! $gene_map_count -eq $dbcount ]; then
        echo "WARNING: $gene_map_count genes in ${abbr}_gene_map.tab, but $dbcount in database!"
        all_counts_correct=0
    else
        echo "Genes count correct ($gene_map_count total)"
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


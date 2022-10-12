#!/bin/bash  

#######################################################
# reactome_gramene_count.sh
#
# Check database for correct number of Reactome-Gramene
# genes and pathways.
#######################################################

section_divide="----------------------------------------------------------------"
all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Get dataset id to help simplify queries
dataset_name="Reactome Gramene data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "Data set '$dataset_name' not in database!"
    # Exit early, nothing to do
    exit 1
fi

# Get *_gene_map.tab input filenames
gene_map_files=$(find /db/*/datasets/reactome_gramene -maxdepth 1 -type f -name *map.tab)

# Iterate through input file list
for gene_map_file in $gene_map_files; do
    taxon_id="4577"
    echo "Checking Reactome Gramene genes and pathways for organism with taxon id $taxon_id"

    # Get number of pathways in database for this organism
    echo "Querying database for pathways..."
    dbcount=$(psql ${dbname} -c "select count(p.id) from pathway p join organism o on o.id=p.organismid join datasetspathway dp on dp.pathway=p.id where dp.datasets=${dataset_id} and o.taxonid='${taxon_id}'" -t -A)
    # Get number of pathways in map_title.tab file for this organism
    map_title_count=$(grep $taxon_id /db/*/datasets/reactome_gramene/map_title.tab | wc -l)
    gene_map_count=$(grep -oE "R-ZMY-[0-9\.\-]+" ${gene_map_file} | sort | uniq | wc -l)
    # Pathway count from map_title.tab and gene_map.tab should agree
    if [ ! $gene_map_count -eq $map_title_count ]; then
        echo "WARNING: $map_title_count pathways in map_title.tab, but $gene_map_count pathways in $gene_map_file!"
        all_counts_correct=0
    fi
    if [ ! $gene_map_count -eq $dbcount ]; then
        echo "WARNING: $gene_map_count pathways in $gene_map_file, but $dbcount pathways in database!"
        all_counts_correct=0
    else
        echo "Pathway count correct ($gene_map_count pathways)"
    fi

    # Query the database for genes and pathways per organism (from gene.pathways collection)
    echo "Querying database for genes and pathways collections..."
    dbcount=$(psql ${dbname} -c "select count(p.identifier) from gene g join organism o on o.id=g.organismid join genespathways gp on gp.genes=g.id join pathway p on p.id=gp.pathways join datasetspathway dp on dp.pathway=p.id where dp.datasets=${dataset_id} and o.taxonid='${taxon_id}'" -t -A)
    gene_map_count=$(grep -o "R-ZMY" $gene_map_file | wc -l)
    if [ ! $gene_map_count -eq $dbcount ]; then
        echo "WARNING: $gene_map_count genes and pathways in $gene_map_file, but $dbcount in database!"
        all_counts_correct=0
    else
        echo "Genes and pathways count correct ($gene_map_count total)"
    fi

    # Query the database for number of genes with pathways per organism
    dbcount=$(psql ${dbname} -c "select count(distinct(g.primaryidentifier)) from gene g join organism o on o.id=g.organismid join genespathways gp on gp.genes=g.id join pathway p on p.id=gp.pathways join datasetspathway dp on dp.pathway=p.id where dp.datasets=${dataset_id} and o.taxonid='${taxon_id}'" -t -A)
    gene_map_count=$(wc -l $gene_map_file | awk '{print $1}')
    if [ ! $gene_map_count -eq $dbcount ]; then
        echo "WARNING: $gene_map_count genes in $gene_map_file, but $dbcount in database!"
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


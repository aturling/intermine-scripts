#!/bin/bash  

########################################################
# horse_dog_test_load.sh
#
# Test load of everything in project.xml for dog and horse.
#
# After loading successfully, run the post processing script.
########################################################

# variables and functions common to all intermine scripts
variablesfile="../../common/script_vars_faangmine1.2.sh"
functionsfile="../../common/intermine_v1_functions.sh"

# files/vars for this script
rundatetime=`date +%Y%m%d%H%M`
logdir="$PWD/log/loading_${rundatetime}"
outfile="${logdir}/script_run.out"

# Source variables file
. $variablesfile

# Source functions file
. $functionsfile

echo "$(timestamp) Script output will be stored in file $outfile"
echo

# Display warning prompt
#warning_prompt

# Get exit code from prompt
#ec=$?

# If exit code is 0, proceed to loading
#if [ $ec -eq 0 ]; then
    # Begin loading
 
    # Create log directory if it doesn't already exist
    if [ ! -d "${logdir}" ]; then
        mkdir ${logdir}
    fi

    startdate=`date`
    echo "$(timestamp) Beginning date and time: ${startdate}" > $outfile
    echo >> $outfile

    # Clear the existing database for a fresh load
    clean_database >> $outfile

    # Get exit code
    ec=$?

    # If exit code != 0, exit early - cannot continue loading
    if [ ! $ec -eq 0 ]; then
        echo "$(timestamp) Stopping loading due to error" >> $outfile
        exit_early >> $outfile
    fi

    # Restart postgres to clear connections
    restart_postgres >> $outfile
    
    #########################
    #                       #
    # BEGIN LOADING SOURCES #
    #                       #
    #########################

    #-----------------------------------------------------------------------------
    # Ontologies
    load_source_with_exit_on_error "uberon" >> $outfile
    load_source_with_exit_on_error "mouse-anatomy-ontology" >> $outfile
    load_source_with_exit_on_error "brenda-tissue-ontology" >> $outfile
    load_source_with_exit_on_error "clinical-measurement-ontology" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "livestock-breed-ontology" >> $outfile
    load_source_with_exit_on_error "livestock-product-trait-ontology" >> $outfile
    load_source_with_exit_on_error "vertebrate-trait-ontology" >> $outfile
    load_source_with_exit_on_error "evidence-ontology" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "psi-mi-ontology" >> $outfile
    load_source_with_exit_on_error "sequence-ontology" >> $outfile
    load_source_with_exit_on_error "gene-ontology" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # BioSample, BioProject, Analysis
    load_source_with_exit_on_error "faang-bioproject" >> $outfile
    load_source_with_exit_on_error "faang-biosample" >> $outfile
    load_source_with_exit_on_error "faang-analysis" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Gene info
    load_source_with_exit_on_error "human-gene-info-refseq" >> $outfile
    load_source_with_exit_on_error "mouse-gene-info-refseq" >> $outfile
    load_source_with_exit_on_error "rat-gene-info-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "human-gene-info-ensembl" >> $outfile
    load_source_with_exit_on_error "mouse-gene-info-ensembl" >> $outfile
    load_source_with_exit_on_error "rat-gene-info-ensembl" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # dbSNP (dog and horse only)
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-I" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-II" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-III" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-IV" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-V" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-VI" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-VII" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-VIII" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-IX" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-X" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-XI" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-XII" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-XIII" >> $outfile
    restart_postgres >> $outfile
    # Empty
    #load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-XIV" >> $outfile
    #load_source_with_exit_on_error "CanFam3.1-dbsnp-variation-XV" >> $outfile

    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-I" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-II" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-III" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-IV" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-V" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-VI" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-VII" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-VIII" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-IX" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-X" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-XI" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-XII" >> $outfile
    restart_postgres >> $outfile
    # Empty
    #load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-XIII" >> $outfile
    #load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-XIV" >> $outfile
    #load_source_with_exit_on_error "EquCab3.0-dbsnp-variation-XV" >> $outfile

    #-----------------------------------------------------------------------------
    # Genome Fasta
    load_source_with_exit_on_error "CanFam3.1_genome_fasta" >> $outfile
    load_source_with_exit_on_error "EquCab3.0_genome_fasta" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # GFF (including new chipseq set)
    load_source_with_exit_on_error "chipseq" >> $outfile
    load_source_with_exit_on_error "CanFam3.1-refseq-coding-gff" >> $outfile
    load_source_with_exit_on_error "CanFam3.1-noncoding-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-refseq-coding-gff" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-noncoding-gff" >> $outfile
    load_source_with_exit_on_error "CanFam3.1-ensembl-gff" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-ensembl-gff" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # RefSeq CDS and Protein Fasta
    load_source_with_exit_on_error "CanFam3.1-cds-refseq" >> $outfile
    load_source_with_exit_on_error "CanFam3.1-protein-refseq" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-cds-refseq" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-protein-refseq" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Ensembl CDS and Protein Fasta
    load_source_with_exit_on_error "CanFam3.1-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "CanFam3.1-protein-ensembl" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-protein-ensembl" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # xrefs
    load_source_with_exit_on_error "dog-xref" >> $outfile
    load_source_with_exit_on_error "horse-xref" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Experiment
    load_source_with_exit_on_error "CanFam3.1-experiment" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-experiment" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Gene expression
    load_source_with_exit_on_error "CanFam3.1-rnaseq-expression-for-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-rnaseq-expression-for-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-rnaseq-expression-for-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-rnaseq-expression-for-ensembl" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Repeat region
    load_source_with_exit_on_error "CanFam3.1-repeat-region" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-repeat-region" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Special case: first iteration uniprot
    # copy properties file over
    cp ${first_iteration_uniprot_props_file} ${uniprot_config_file}
    load_source_with_exit_on_error "uniprot-first" >> $outfile
    restart_postgres >> $outfile

    # Special case: second iteration uniprot
    # copy properties file over
    cp ${second_iteration_uniprot_props_file} ${uniprot_config_file}
    load_source_with_exit_on_error "uniprot-sec" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Misc. rest of project.xml items
    load_source_with_exit_on_error "uniprot-keywords" >> $outfile
    load_source_with_exit_on_error "uniprot-fasta" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "interpro" >> $outfile
    load_source_with_exit_on_error "protein2ipr" >> $outfile
    load_source_with_exit_on_error "reactome" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ncbi-pubmed-gene" >> $outfile
    load_source_with_exit_on_error "ensembl-pubmed-gene" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ensembl-compara" >> $outfile
    load_source_with_exit_on_error "treefam-extended" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "orthodb" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "omim" >> $outfile
    load_source_with_exit_on_error "bovine-biogrid" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "psi-intact" >> $outfile
    load_source_with_exit_on_error "kegg" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "entrez-organism" >> $outfile
    load_source_with_exit_on_error "update-publications" >> $outfile

    #########################

    # After loading all sources successfully, exit script and send email notification
    echo >> $outfile
    echo "$(timestamp) Loading completed" >> $outfile

    enddate=`date`
    echo >> $outfile
    echo "$(timestamp) End date and time: ${enddate}" >> $outfile

    send_email

#fi
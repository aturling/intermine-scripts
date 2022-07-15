#!/bin/bash  

########################################################
# test_load.sh
#
# Testing maizemine orthologs etc.
########################################################

# variables and functions common to all intermine scripts
variablesfile="../../common/script_vars_maizemine1.3.sh"
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
ec=0 # force no prompt

# If exit code is 0, proceed to loading
if [ $ec -eq 0 ]; then
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

    load_source_with_exit_on_error "biomart" >> $outfile
    load_source_with_exit_on_error "maize-dna-v3-fasta" >> $outfile
    load_source_with_exit_on_error "maize-dna-v4-fasta" >> $outfile
    load_source_with_exit_on_error "additional_identifiers" >> $outfile

    restart_postgres >> $outfile

    load_source_with_exit_on_error "maize-gene-model-v3-gff" >> $outfile
    load_source_with_exit_on_error "maize-gene-model-v4-gff" >> $outfile
    load_source_with_exit_on_error "maize-gene-model-v4-gff-rejected" >> $outfile
    load_source_with_exit_on_error "maize-refseq-proteincoding-gff" >> $outfile

    restart_postgres >> $outfile

    load_source_with_exit_on_error "maize-refseq-noncoding-gff" >> $outfile
    load_source_with_exit_on_error "maize-cds-v3-fasta"  >> $outfile
    load_source_with_exit_on_error "maize-cds-v4-fasta"  >> $outfile
    load_source_with_exit_on_error "maize-cds-refseq-fasta" >> $outfile

    restart_postgres >> $outfile

    load_source_with_exit_on_error "maize-pep-v3-fasta" >> $outfile
    load_source_with_exit_on_error "maize-pep-v4-fasta" >> $outfile
    load_source_with_exit_on_error "maize-protein-refseq-fasta" >> $outfile
    load_source_with_exit_on_error "entrez-organism2" >> $outfile 

    # Special case: first iteration uniprot
    # copy properties file over
    #cp ${first_iteration_uniprot_props_file} ${uniprot_config_file}
    #load_source_with_exit_on_error "uniprot-to-ncbi" >> $outfile

    # Special case: second iteration uniprot
    # copy properties file over
    #cp ${second_iteration_uniprot_props_file} ${uniprot_config_file}
    #load_source_with_exit_on_error "uniprot-to-ogs" >> $outfile

    #########################

    # After loading all sources successfully, exit script and send email notification
    echo >> $outfile
    echo "$(timestamp) Loading completed" >> $outfile

    enddate=`date`
    echo >> $outfile
    echo "$(timestamp) End date and time: ${enddate}" >> $outfile

    send_email

fi

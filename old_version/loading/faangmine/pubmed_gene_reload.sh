#!/bin/bash  

########################################################
# pubmed_gene_reload.sh
#
# Testing db fix for incorrect pubmed gene load.
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
ec=0 # skipping prompt for now

# If exit code is 0, proceed to loading
if [ $ec -eq 0 ]; then
    # Begin loading
 
    # Create log directory if it doesn't already exist
    if [ ! -d "${logdir}" ]; then
        mkdir -p ${logdir}
    fi

    startdate=`date`
    echo "$(timestamp) Beginning date and time: ${startdate}" > $outfile
    echo >> $outfile

    # Restart postgres to clear connections
    restart_postgres >> $outfile
    
    #########################
    #                       #
    # BEGIN LOADING SOURCES #
    #                       #
    #########################

    load_source_with_exit_on_error "ncbi-pubmed-gene-reload" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ncbi-pubmed-gene-additions" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ensembl-pubmed-gene-reload" >> $outfile

    #########################

    # After loading all sources successfully, exit script and send email notification
    echo >> $outfile
    echo "$(timestamp) Loading completed" >> $outfile

    enddate=`date`
    echo >> $outfile
    echo "$(timestamp) End date and time: ${enddate}" >> $outfile

    send_email

fi

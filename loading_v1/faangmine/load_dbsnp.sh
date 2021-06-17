#!/bin/bash  

########################################################
# Load pig dbSNP (into clean database)
########################################################

# variables and functions common to all intermine scripts
variablesfile="~/intermine-scripts/common/script_vars_faangmine1.2.sh"
functionsfile="$PWD/common/intermine_functions.sh"

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
ec=$?

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

    # This part of the script will need to be customized for each load.
    # For each sourcename in project.xml, run load_source_with_exit_on_error <sourcename>
    # which will attempt to load the source and exit the script early upon failure.
    # After several loads, it may be necessary to restart postgres and sleep for a couple of minutes.

    # Example 1: load a single source named A
    # load_source_with_exit_on_error "A" >> $outfile

    # Example 2: load multiple sources in a row named A, B, C, D
    # load_source_with_exit_on_error "A" >> $outfile
    # load_source_with_exit_on_error "B" >> $outfile
    # load_source_with_exit_on_error "C" >> $outfile
    # load_source_with_exit_on_error "D" >> $outfile

    # Example 3: load multiple sources in a row named A, B, C, D, then restart postgres to clear connections before loading next set
    # load_source_with_exit_on_error "A" >> $outfile
    # load_source_with_exit_on_error "B" >> $outfile
    # load_source_with_exit_on_error "C" >> $outfile
    # load_source_with_exit_on_error "D" >> $outfile
    # restart_postgres >> $outfile

    # Special case: first iteration uniprot
    # copy properties file over
    #cp ${first_iteration_uniprot_props_file} ${uniprot_config_file}
    #load_source_with_exit_on_error "uniprot-to-ncbi" >> $outfile

    # Special case: second iteration uniprot
    # copy properties file over
    #cp ${second_iteration_uniprot_props_file} ${uniprot_config_file}
    #load_source_with_exit_on_error "uniprot-to-ogs" >> $outfile

    # First test single pig dbSNP
    # Need bioproject, biosample, and analysis tables first
    load_source_with_exit_on_error "faang-bioproject" >> $outfile
    load_source_with_exit_on_error "faang-biosample" >> $outfile
    load_source_with_exit_on_error "faang-analysis" >> $outfile
    restart_postgres >> $outfile

    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-I" >> $outfile
    restart_postgres >> $outfile

    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-II" >> $outfile
    restart_postgres >> $outfile

    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-III" >> $outfile
    restart_postgres >> $outfile

    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-IV" >> $outfile
    restart_postgres >> $outfile

    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-V" >> $outfile
    restart_postgres >> $outfile

    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-VI" >> $outfile
    restart_postgres >> $outfile

    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-VII" >> $outfile
    restart_postgres >> $outfile

    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-VIII" >> $outfile
    restart_postgres >> $outfile

    # rest are empty
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-IX" >> $outfile
    #restart_postgres >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-X" >> $outfile
    #restart_postgres >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-XI" >> $outfile
    #restart_postgres >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-XII" >> $outfile
    #restart_postgres >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-XIII" >> $outfile
    #restart_postgres >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-XIV" >> $outfile
    #restart_postgres >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-XV" >> $outfile
    #restart_postgres >> $outfile

    #########################

    # After loading all sources successfully, exit script and send email notification
    echo >> $outfile
    echo "$(timestamp) Loading completed" >> $outfile

    enddate=`date`
    echo >> $outfile
    echo "$(timestamp) End date and time: ${enddate}" >> $outfile

    send_email

#fi

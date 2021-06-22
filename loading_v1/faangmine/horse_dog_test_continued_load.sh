#!/bin/bash  

########################################################
# horse_dog_test_continued_load.sh
#
# Test load of everything in project.xml for dog and horse.
# Continue where left off after an error - don't reset the
# database!
#
# After loading successfully, run the post processing script.
########################################################

# variables and functions common to all intermine scripts
variablesfile="~/intermine-scripts/common/script_vars_faangmine1.2.sh"
functionsfile="~/intermine-scripts/common/intermine_v1_functions.sh"

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

    # Restart postgres to clear connections
    restart_postgres >> $outfile
    
    #########################
    #                       #
    # BEGIN LOADING SOURCES #
    #                       #
    #########################

    # Left off just before here:
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

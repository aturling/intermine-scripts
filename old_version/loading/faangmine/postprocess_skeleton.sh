#!/bin/bash  

########################################################
# postprocess_skeleton.sh
#
# This is the basic outline for a postprocessing script.
# It is not meant to be run on its own. To use, copy this
# script to another name in the same directory and add the
# postprocessing step names from project.xml with database
# restarts in the appropriate places.
#
########################################################

# variables and functions common to all intermine scripts
variablesfile="../../common/script_vars_faangmine1.2.sh"
functionsfile="../../common/intermine_v1_functions.sh"

# files/vars for this script
rundatetime=`date +%Y%m%d%H%M`
logdir="$PWD/log/postprocessing_${rundatetime}"
outfile="${logdir}/script_run.out"

# Source variables file
. $variablesfile

# Source functions file
. $functionsfile

# Create log directory if it doesn't already exist
if [ ! -d "${logdir}" ]; then
    mkdir ${logdir}
fi

echo "$(timestamp) Script output will be stored in file $outfile"
echo

startdate=`date`
echo "$(timestamp) Beginning date and time: ${startdate}" > $outfile
echo >> $outfile

# Restart postgres to clear connections
restart_postgres >> $outfile

########################
#                      #
# BEGIN POSTPROCESSING #
#                      #
########################

# This part of the script will need to be customized for each postprocessing run.
# For each postprocess step in project.xml, run postprocess_with_exit_on_error <postprocess step name>
# which will attempt to run the postprocessing step and exit the script early upon failure.
# It may be necessary to restart postgres after each step or after running several steps at a time.

# Example: run postprocessing steps named A and B
# postprocess_with_exit_on_error "A" >> $outfile
# restart_postgres >> $outfile
# postprocess_with_exit_on_error "B" >> $outfile
# restart_postgres >> $outfile

########################

# After postprocessing successfully, exit script and send email notification

echo >> $outfile
echo "$(timestamp) Postprocessing completed" >> $outfile

enddate=`date`
echo >> $outfile
echo "$(timestamp) End date and time: ${enddate}" >> $outfile

send_email


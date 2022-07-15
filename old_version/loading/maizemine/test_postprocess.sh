#!/bin/bash  

########################################################
# test_postprocess.sh
########################################################

# variables and functions common to all intermine scripts
variablesfile="../../common/script_vars_maizemine1.3.sh"
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

postprocess_with_exit_on_error "create-chromosome-locations-and-lengths" >> $outfile
postprocess_with_exit_on_error "create-references" >> $outfile
postprocess_with_exit_on_error "transfer-sequences"  >> $outfile

restart_postgres >> $outfile

postprocess_with_exit_on_error "create-overlap-view" >> $outfile
postprocess_with_exit_on_error "create-location-overlap-index" >> $outfile
postprocess_with_exit_on_error "do-sources"  >> $outfile

restart_postgres >> $outfile

postprocess_with_exit_on_error "create-attribute-indexes" >> $outfile
postprocess_with_exit_on_error "create-search-index" >> $outfile

restart_postgres >> $outfile

postprocess_with_exit_on_error "summarise-objectstore"  >> $outfile
postprocess_with_exit_on_error "create-autocomplete-index" >> $outfile

########################

# After postprocessing successfully, exit script and send email notification

echo >> $outfile
echo "$(timestamp) Postprocessing completed" >> $outfile

enddate=`date`
echo >> $outfile
echo "$(timestamp) End date and time: ${enddate}" >> $outfile

send_email


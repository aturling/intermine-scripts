#!/bin/bash  

########################################################
# webapp_postprocess.sh
#
# Runs only webapp-related post-processing steps from 
# project.xml
########################################################

# variables and functions common to all intermine scripts
variablesfile="~/intermine-scripts/common/script_vars_faangmine1.2.sh"
functionsfile="~/intermine-scripts/common/intermine_v1_functions.sh"

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
    mkdir -p ${logdir}
fi

echo "$(timestamp) Script output will be stored in file $outfile"
echo

startdate=`date`
echo "$(timestamp) Beginning date and time: ${startdate}" > $outfile
echo >> $outfile

# Restart postgres to clear connections
restart_postgres >> $outfile

# Redo webapp postprocessing steps
#postprocess_with_exit_on_error "create-attribute-indexes" >> $outfile
#restart_postgres >> $outfile
postprocess_with_exit_on_error "create-search-index" >> $outfile
restart_postgres >> $outfile
postprocess_with_exit_on_error "summarise-objectstore" >> $outfile
restart_postgres >> $outfile
postprocess_with_exit_on_error "create-autocomplete-index" >> $outfile

########################

# After postprocessing successfully, exit script and send email notification

echo >> $outfile
echo "$(timestamp) Postprocessing completed" >> $outfile

enddate=`date`
echo >> $outfile
echo "$(timestamp) End date and time: ${enddate}" >> $outfile

send_email


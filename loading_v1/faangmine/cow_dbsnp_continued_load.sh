#!/bin/bash  

########################################################
# Continue loading dbsnp sources - DO NOT wipe db first.
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

# Cow dbSNP

load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-I" >> $outfile
restart_postgres >> $outfile

load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-II" >> $outfile
restart_postgres >> $outfile

load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-III" >> $outfile
restart_postgres >> $outfile

load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-IV" >> $outfile
restart_postgres >> $outfile

load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-V" >> $outfile
restart_postgres >> $outfile

load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-VI" >> $outfile
restart_postgres >> $outfile

load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-VII" >> $outfile
restart_postgres >> $outfile

load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-VIII" >> $outfile
restart_postgres >> $outfile

load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-IX" >> $outfile
restart_postgres >> $outfile

load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-X" >> $outfile
restart_postgres >> $outfile

load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-XI" >> $outfile

# Empty
#load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-XII" >> $outfile
#load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-XIII" >> $outfile
#load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-XIV" >> $outfile
#load_source_with_exit_on_error "ARS-UCD1.2-dbsnp-variation-XV" >> $outfile

#########################

# After loading all sources successfully, exit script and send email notification
echo >> $outfile
echo "$(timestamp) Loading completed" >> $outfile

enddate=`date`
echo >> $outfile
echo "$(timestamp) End date and time: ${enddate}" >> $outfile

send_email

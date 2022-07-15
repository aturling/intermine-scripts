#!/bin/bash  

#####################################################
# test_independent_sources_loading_basic.sh
#
# This script tests loading sources with source names
# specified in an input (text) file.
# Each source is loaded independently (database
# cleaned between source loads).
# This test checks for basic errors, such as an
# input data file being formatted incorrectly.
#####################################################

# variables and functions common to all test scripts
variablesfile="../../common/script_vars_maizemine1.3.sh"
functionsfile="../../common/intermine_v1_functions.sh"

# files/vars for this script
inputfile="$PWD/input_files/test_source_names.txt"
inputfile_has_header=0 # set to 1 if first line of input file is header line
rundatetime=`date +%Y%m%d%H%M`
logdir="$PWD/log/log_test_independent_sources_loading_basic_${rundatetime}"
outfile="${logdir}/script_run.out"

# Source variables file
. $variablesfile

# Source functions file
. $functionsfile

# Display warning prompt
warning_prompt

# Get exit code from prompt
ec=$?

# If exit code is 0, proceed to tests
if [ $ec -eq 0 ]; then
    # Begin tests
    echo
    echo "$(timestamp) Beginning tests"
    echo "$(timestamp) Script output will be logged in ${outfile}"
    echo

    # Create log directory if it doesn't already exist
    if [ ! -d "${logdir}" ]; then
        mkdir ${logdir}
    fi

    startdate=`date`
    echo "$(timestamp) Beginning date and time: ${startdate}" > $outfile
    echo >> $outfile

    # Check if expected input file exists
    if [ ! -f "${inputfile}" ]; then
        echo "$(timestamp) ERROR: Input file ${inputfile} does not exist." >> $outfile
    else
        echo "$(timestamp) Reading source names from input file ${inputfile}" >> $outfile

        # Loop through input file contents - skip first line if header exists
        {
            if [ $inputfile_has_header -eq 1 ]; then
                read  # skip first line
            fi
            while read sourcename; do
                echo >> $outfile
                echo "$(timestamp) Testing source: ${sourcename}" >> $outfile
                echo >> $outfile

                # Clean database
                clean_database >> $outfile

                # Get exit code
                ec=$?

                # If exit code != 0, exit testing early - can't continue tests if this step fails
                if [ ! $ec -eq 0 ]; then
                    echo "$(timestamp) Stopping tests due to error" >> $outfile
                    break
                fi

                # Load source
                load_source ${sourcename} >> $outfile
                echo >> $outfile
            done
        } < ${inputfile}
        echo >> $outfile
        echo "$(timestamp) Tests completed" >> $outfile
    fi

    enddate=`date`
    echo >> $outfile
    echo "$(timestamp) End date and time: ${enddate}" >> $outfile
fi

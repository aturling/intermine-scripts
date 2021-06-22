#!/bin/bash  

########################################################
# test_independent_sources_loading_with_gene_counts.sh
#
# This script tests loading sources and compares the
# gene count in the database after loading with the
# expected gene count from the file names, where the 
# source names and expected gene counts are specified
# in an input (csv) file.
#
# IMPORTANT: Each line of the input file must have the 
# format:
#
# source_name,gene_count_from_file
#
# with NO spaces or special characters besides the 
# comma separator.
#
# Each source is loaded independently (database
# cleaned between source loads).
#
# The output is a csv file of the form:
# source_name,gene_count_from_file,gene_count_from_db
########################################################

# variables and functions common to all test scripts
variablesfile="~/intermine-scripts/common/script_vars_maizemine1.3.sh"
functionsfile="~/intermine-scripts/common/intermine_v1_functions.sh"

# files/vars for this script
inputfile="$PWD/input_files/refseq_sources_and_counts.csv"
inputfile_has_header=1 # set to 1 if first line of input file is header line
rundatetime=`date +%Y%m%d%H%M`
logdir="$PWD/log/log_test_independent_sources_loading_with_gene_counts_${rundatetime}"
outfile="${logdir}/script_run.out"
resultsfile="${logdir}/gene_counts.csv"

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
    echo "Beginning tests"
    echo
    echo "Script output will be logged in ${outfile}"
    echo

    # Create log directory if it doesn't already exist
    if [ ! -d "${logdir}" ]; then
        mkdir ${logdir}
    fi

    startdate=`date`
    echo "Beginning date and time: ${startdate}" > $outfile
    echo >> $outfile

    # Check if expected input file exists
    if [ ! -f "${inputfile}" ]; then
        echo "ERROR: Input file ${inputfile} does not exist." >> $outfile
    else
        echo "Reading source names and gene counts from input file ${inputfile}" >> $outfile
        echo >> $outfile
        echo "Results will be stored in ${resultsfile}" >> $outfile
        echo >> $outfile
        echo "Results will be stored in ${resultsfile}" # show on screen too
        echo

        # Create header for results file
        echo "source_name,gene_count_from_file,gene_count_from_database" > $resultsfile

        # Loop through input file contents - skip first line if header exists
        {
            if [ $inputfile_has_header -eq 1 ]; then
                read  # skip first line
            fi
            while IFS=, read sourcename gene_count; do
                echo "Testing source: ${sourcename}" >> $outfile
                echo "Expected gene count is: ${gene_count}" >> $outfile

                # Initialize gene count from database to 0 which will indicate an error if it
                # is not overwritten (or ovewritten to 0) since every load should result in a nonzero
                # number of genes
                dbcount=0

                # Clean database
                clean_database >> $outfile

                # Get exit code
                ec=$?

                # If exit code != 0, exit testing early - can't continue tests if this step fails
                if [ ! $ec -eq 0 ]; then
                    echo "Stopping tests due to error" >> $outfile
                    break
                fi

                # Load source into database
                load_source ${sourcename} >> $outfile

                # Get exit code from loading source
                ec=$?
      
                # If exit code is 0, load was successful so we can go ahead and do the db query
                if [ $ec -eq 0 ]; then
                    # Run postgres query to obtain gene count from database after loading source
                    dbcount=$(psql -U ${dbuser} -d ${dbname} -c 'SELECT COUNT(*) FROM gene' -t -A 2>>$outfile)

                    # Get exit code from db query
                    ec=$?

                    # If exit code !=0, alert that error occurred and set dbcount=ERR (string) explicitly
                    if [ ! $ec -eq 0 ]; then
                        echo "ERROR: Database query failed" >> $outfile
                        dbcount="ERR"
                    fi

                    echo "Gene count from database is: ${dbcount}" >> $outfile
                fi

                # Store csv line in results file
                echo "${sourcename},${gene_count},${dbcount}" >> $resultsfile

                echo >> $outfile
            done
        } < ${inputfile}
        echo "Tests completed" >> $outfile
    fi

    enddate=`date`
    echo >> $outfile
    echo "End date and time: ${enddate}" >> $outfile
fi

#!/bin/bash  

########################################################
# test_independent_sources_loading_with_db_queries.sh
#
# This script tests loading sources of various types and
# performs follow-up database queries after loading to
# ensure that data successfully loaded into the database.
#
# The tables to be queried are specified in the file
# types/<typename>.csv which has the format:
#
# tablename,dbdumpbool
#
# where tablename is the table name to be queried (e.g., gene)
# and dbdumpbool is equal to 1 if the query should be run as a
# "SELECT * from tablename limit 500" statement with the 
# result dumped to a file, or 0 if only the count should be
# stored (i.e., "SELECT COUNT(*) from tablename")
# All counts are run whether dbdumpbool is 0 or 1 and the
# counts are stored in the outputfile
# <logdir>/dbqueries/<sourcename>_db_counts.csv
# which has the format:
# tablename,count
#
# Additionally, the query dumps are stored in separate
# files
# <logdir>/dbqueries/<sourcename>_<tablename>_select.csv
#
# IMPORTANT: Each line of the input file must have the 
# format:
#
# source_name,type
#
# with NO spaces or special characters besides the 
# comma separator, and the type must appear in the
# types/ folder as <type>.csv.
#
# Each source is loaded independently (database
# cleaned between source loads).
########################################################

# variables and functions common to all test scripts
variablesfile="~/intermine-scripts/common/script_vars_maizemine1.3.sh"
functionsfile="~/intermine-scripts/common/intermine_v1_functions.sh"

# files/vars for this script
inputfile="$PWD/input_files/all_sources_and_types.csv"
inputfile_has_header=1 # set to 1 if first line of input file is header line
inputtypesdir="$PWD/input_files/types"
rundatetime=`date +%Y%m%d%H%M`
logdir="$PWD/log/log_test_independent_sources_loading_with_db_queries_${rundatetime}"
dboutputdir="${logdir}/dbqueries"
loadresultsfile="${logdir}/load_status_all_sources.csv"
outfile="${logdir}/script_run.out"

# Source variables file
. $variablesfile

# Source functions file
. $functionsfile

echo "Script output will be stored in file $outfile"
echo

# Display warning prompt
warning_prompt

# Get exit code from prompt
ec=$?

# If exit code is 0, proceed to tests
if [ $ec -eq 0 ]; then
    # Begin tests

    # Create log directory if it doesn't already exist
    if [ ! -d "${logdir}" ]; then
        mkdir ${logdir}
    fi

    # Create database queries output directory
    mkdir ${dboutputdir}

    startdate=`date`
    echo "Beginning date and time: ${startdate}" > $outfile
    echo >> $outfile

    # Check if expected input file exists
    if [ ! -f "${inputfile}" ]; then
        echo "ERROR: Input file ${inputfile} does not exist." >> $outfile
    else
        echo "Reading source names and types from input file ${inputfile}" >> $outfile
        echo >> $outfile

        # Create header for output file for status summary for test loads of all sources from input file
        echo "sourcename,loading_status" > $loadresultsfile

        echo "Loading status for all sources will be stored in file ${loadresultsfile}" >> $outfile
        echo >> $outfile

        # Loop through input file contents - skip first line if header exists
        {
            if [ $inputfile_has_header -eq 1 ]; then
                read  # skip first line
            fi
            while IFS=, read sourcename sourcetype; do
                echo "Testing source: ${sourcename}" >> $outfile
                echo "Source type is: ${sourcetype}" >> $outfile

                # Clean database
                clean_database >> $outfile

                # Get exit code
                ec=$?

                # If exit code != 0, exit testing early - can't continue tests if this step fails
                if [ ! $ec -eq 0 ]; then
                    echo "Stopping tests due to error" >> $outfile
                    break
                fi

                # Initialize loading status to failure
                loadstatus="FAIL"

                # Load source into database
                load_source ${sourcename} >> $outfile

                # Get exit code from loading source
                ec=$?
      
                # If exit code is 0, load was successful so we can go ahead and do the db queries
                if [ $ec -eq 0 ]; then
                    # Set loading status to successful
                    loadstatus="SUCCESS"

                    # First check that the types file exists, and if not, report error and move on
                    typefile=${inputtypesdir}/${sourcetype}.csv
                    echo "Verifying that type file $typefile exists" >> $outfile
                    if [ ! -f "${typefile}" ]; then
                        echo "ERROR: Expected type file $typefile does not exist." >> $outfile
                    else
                        echo "Beginning database queries" >> $outfile
                
                        # Output file for database table counts
                        countresultsfile="${dboutputdir}/${sourcename}_db_counts.csv"
                        echo "Row counts for table(s) will be stored in file ${countresultsfile}" >> $outfile   
 
                        # Add header line to count output file
                        echo "tablename,count" > $countresultsfile

                        # Loop over contents of type file
                        while IFS=, read tablename dbdumpbool; do
                            echo "Querying table ${tablename}" >> $outfile
                    
                            # Run postgres query to get row count for table         
                            rowcount=$(psql -U ${dbuser} -d ${dbname} -c "SELECT COUNT(*) FROM $tablename" -t -A 2>>$outfile)
              
                            # Get exit code from db query
                            ec=$?

                            # If exit code !=0, alert that error occurred and set rowcount=ERR (string)
                            if [ ! $ec -eq 0 ]; then
                                echo "ERROR: Database query failed" >> $outfile
                                rowcount="ERR"
                            fi

                            # Store the results in the count file
                            echo "${tablename},${rowcount}" >> $countresultsfile

                            # Additionally, if dbdumpbool is 1, do a select * from table limit 500 and dump results to file
                            if [ ${dbdumpbool} -eq 1 ]; then
                                # Output file for dbdump
                                dbdumpfile="${dboutputdir}/${sourcename}_${tablename}_select.csv"

                                echo "Additionally dumping first 500 rows of table ${tablename} to file ${dbdumpfile}" >> $outfile

                                # Run postgres query to get row output limited to first 500 rows, also change bars to commas
                                psql -U ${dbuser} -d ${dbname} -c "SELECT * FROM $tablename limit 500" -A | sed 's/|/,/g' 2>>$outfile 1>$dbdumpfile 
                            fi    
                        done < ${typefile}
                        echo "Database queries completed" >> $outfile
                    fi
                    #echo "Gene count from database is: ${dbcount}" >> $outfile
                fi
               
                # Report loading status to file
                echo "${sourcename},${loadstatus}" >> $loadresultsfile

                echo >> $outfile   # double-space between sources

            done
        } < ${inputfile}
        echo "Tests completed" >> $outfile
    fi

    enddate=`date`
    echo >> $outfile
    echo "End date and time: ${enddate}" >> $outfile
fi

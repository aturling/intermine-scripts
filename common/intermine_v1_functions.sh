#!/bin/bash  

# Function timestamp
# Expects no input
# Outputs timestamp for logfiles
function timestamp() {
    date +'[%a %b %d %H:%M:%S]'
}

# Function freemem
# Expects no input
# Outputs free memory in GB
function freemem() {
    awk '/MemFree/ { printf "%.3f \n", $2/1024/1024 }' /proc/meminfo
}

# Function warning_prompt
# Expects no input (gets user input from command line)
# Returns 0 if success (warning accepted), 1 otherwise
function warning_prompt() {
    echo "WARNING: This script will clear the current database."
    read -p "Continue (y/n)? " REPLY
    if [ "$REPLY" != "y" ]; then
        echo "Exiting - no changes were made to the database."
        return 1
    else
        return 0
    fi
}


# Function restart_postgres
# Expects no input
# Restarts postgres and waits a bit to clear connections
# Note this will require that the user running the script has permission to restart
# postgres with sudo with no password (as indicated in /etc/sudoers file)
function restart_postgres() {
    echo
    echo "$(timestamp) Free memory: $(freemem) GB"
    echo "$(timestamp) Restarting postgres"
    sudo -n systemctl restart postgresql-9.5
    sleep 5m
    echo "$(timestamp) Done restarting"
    echo "$(timestamp) Free memory: $(freemem) GB"
    echo
}


# Function send_email
# Expects no input
# Sends an e-mail to intermine user to say that script has stopped running (for whatever reason)
function send_email() {
    # Send e-mail notification that script has finished running
    echo "See $outfile for details. (This is an automated message.)" | mail -s "Intermine script has finished running" $notifyemail
}


# Function: exit_early
# Exits script early (generally due to an error) and sends an e-mail that script has finished running
# Input is exit code (0 success, 1 error) - defaults to error if no input
function exit_early() {
    # Get exit code from input, if present (default to error otherwise)
    local ec=$1
    if [ -z $ec ] ; then
        ec=1
    fi

    # Report early exit
    echo
    echo "$(timestamp) Exiting script early"
 
    local enddate=`date`
    echo
    echo "$(timestamp) End date and time: ${enddate}"

    # Send e-mail notification
    send_email

    # Exit with exit code
    if [ $ec -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}


# Function: clean_database
# Expects no input
# Runs ant clean build-db in the appropriate directory
# Returns exit code from ant command
function clean_database () {
    echo "$(timestamp) running ant clean build-db"

    # Create log file
    local logfile="${logdir}/clean_build_db.log"

    # Go to dbmodel directory and clear database
    cd ${dbmodeldir}
    ant clean build-db > $logfile 2>&1

    # Get exit code
    local ec=$?

    # Check exit code
    if [ $ec -eq 0 ]; then
        echo "$(timestamp) ant clean build-db ran successfully"
    else
        echo "$(timestamp) error with running ant clean build-db"
        echo "$(timestamp) check log file ${logfile} for more information"
    fi

    return $ec
}

# Function: load_source
# Expects input to be source name (string)
# Runs ant command to load source into database
function load_source () {
    # Get source name input argument
    local sourcename=$1
    if [ -z $sourcename ] ; then
        echo "$(timestamp) Error: no source name found"
        return 1
    else
        # Create log file for output
        local logfile="${logdir}/load_source_${sourcename}.log"

        # Go to integrate directory
        cd ${integratedir}

        # First run ant clean to clear out stuff (logs, etc.) from last load:
        echo "$(timestamp) running ant clean"
        ant clean > $logfile 2>&1

        # Load source into database
        echo "$(timestamp) running ant -Dsource=${sourcename} -v"
        ant -Dsource=${sourcename} -v > $logfile 2>&1

        # Get exit code
        local ec=$?

        # Check exit code
        # New: copy the log file in both outcomes to review later if needed
        local sourcelogfilenamebase="${logdir}/intermine_log_${sourcename}"
        if [ $ec -eq 0 ]; then
            local successlogfile="${sourcelogfilenamebase}.log"
            cp ${integratelogfile} ${successlogfile}
            echo "$(timestamp) source ${sourcename} loaded successfully"
            return 0
        else
            local errlogfile="${sourcelogfilenamebase}.err"
            cp ${integratelogfile} ${errlogfile}
            echo "$(timestamp) Error with loading source ${sourcename}; see log file ${errlogfile} for more information"
            return 1
        fi
    fi
}

# Function load_source_with_exit_on_error
# Expects input to be source name (string)
# Calls load_source but exits the script early if there is an error
function load_source_with_exit_on_error {
    local sourcename=$1
    if [ -z $sourcename ] ; then
        echo "$(timestamp) Error: no source name found"
        # Exit script early because this will not result in a successful load...
        exit_early
    else
        load_source $sourcename

        # Get exit code
        local ec=$?

        # Check exit code - if not zero, exit script early
        # (Note that error has already been reported in load_source function)
        if [ ! $ec -eq 0 ]; then
            exit_early
        fi
    fi
}


# Function postprocess
# Expects postprocess name as input (string)
# Runs ant command to run postprocessing step
function postprocess() {
    local postprocessname=$1
    if [ -z $postprocessname ] ; then
        echo "$(timestamp) Error: no postprocessing name found"
        return 1       
    else
        # Create log file for output
        local logfile="${logdir}/postprocess_name_${postprocessname}.log"

        # Go to postprocess directory
        cd ${postprocessdir}

        # First run ant clean to clear out stuff (logs, etc.) from last load:
        echo "$(timestamp) running ant clean"
        ant clean > $logfile 2>&1

        # Run postprocessing step
        echo "$(timestamp) running ant -Daction=${postprocessname} -v"
        ant -Daction=${postprocessname} -v > $logfile 2>&1

        # Get exit code
        local ec=$?

        # Check exit code
        if [ $ec -eq 0 ]; then
            echo "$(timestamp) Postprocessing step ${postprocessname} ran successfully"
            return 0
        else
            # Copy the intermine log over for viewing errors
            local errlogfile="${logdir}/intermine_log_${postprocessname}.err"
            cp ${postprocesslogfile} ${errlogfile}
            echo "$(timestamp) Error with running postprocessing step ${postprocessname}; see log file ${errlogfile} for more information"
            return 1
        fi
    fi
}


# Function postprocess_with_exit_on_error
# Expects postprocess name as input (string)
# Calls postprocess but exits script early if there is an error
function postprocess_with_exit_on_error() {
    local postprocessname=$1
    if [ -z $postprocessname ] ; then
        echo "$(timestamp) Error: no postprocessing name found"
        # Abort mission
        exit_early
    else
        postprocess $postprocessname

        # Get exit code
        local ec=$?

        # Check exit code - if not zero, exit script early
        # (Note that error has already been reported in postprocess function)
        if [ ! $ec -eq 0 ]; then
            exit_early
        fi
    fi
}

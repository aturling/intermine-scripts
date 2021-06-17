#!/bin/bash  

######################################################
# build_db_with_email_notify.sh
#
# Run project_build script and send e-mail when done.
######################################################

# Run project_build script

# Load variables
variablesfile="$PWD/common/script_vars_hymenopteramine1.5.sh"
. $variablesfile

# Create log directory if it doesn't already exist
if [ ! -d "${log_dir}" ]; then
    mkdir ${log_dir}
fi

echo "Script output will be stored in file $script_outfile"

cd ${mine_home_dir}
./gradlew clean > ${script_outfile} 2>&1 
./gradlew buildDB >> ${script_outfile} 2>&1
./project_build -b localhost ${build_dir} >> ${script_outfile} 2>&1

# Get exit code
ec=$?

if [ ! $ec -eq 0 ]; then
    mail_subj="${mail_subj} error"
    mail_msg="${mail_msg} stopped early due to error. See ${script_outfile} for details."
else
    mail_subj="${mail_subj} finished"
    mail_msg="${mail_msg} finished running.  See ${script_outfile} for script output."
fi

mail_msg="${mail_msg} (This is an automated message.)"
echo "${mail_msg}" | mail -s "${mail_subj}" $notify_email

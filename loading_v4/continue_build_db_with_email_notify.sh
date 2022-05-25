#!/bin/bash  

######################################################
# build_db_with_email_notify.sh
#
# Run project_build script and send e-mail when done.
######################################################

#next_source="summarise-objectstore"
source_list="'so,go,*fasta,*gff,*gene-info*,*refseq-cds,*refseq-protein,*ensembl-cds,*ensembl-protein,*xref,kegg'"

# Run project_build script

scriptname=`basename "$0"`

if [ $# -eq 0 ]; then
    echo "Usage  : ./${scriptname} <variables_file_location>"
    echo "Example: ./${scriptname} ~/intermine-scripts/common/script_vars_faangmine1.2.sh"
    exit 1
fi

# variables
variablesfile=$1

. $variablesfile

# Create log directory if it doesn't already exist
if [ ! -d "${log_dir}" ]; then
    mkdir ${log_dir}
fi

echo "Script output will be stored in file $script_outfile"

cd ${mine_home_dir}
#./project_build -a ${next_source}- localhost ${build_dir} >> ${script_outfile} 2>&1
./project_build -b -a "${source_list}" localhost ${build_dir} >> ${script_outfile} 2>&1

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
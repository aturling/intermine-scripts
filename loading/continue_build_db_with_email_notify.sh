#!/bin/bash  

######################################################
# continue_build_db_with_email_notify.sh
#
# Run project_build script with subset of sources and 
# send e-mail when done.
######################################################

next_source="create-chromosome-locations-and-lengths"
#source_list="evidence-ontology,*fasta,*qtl-gff,uniprot*,kegg,entrez-organism,do-sources,create-attribute-indexes"
source_list="so,evidence-ontology,ensembl-compara"

scriptname=`basename "$0"`
scriptpath=`dirname $(readlink -f $0)`
log_dir="${scriptpath}/log"

# Run project_build script

scriptname=`basename "$0"`

# variables
. ~/intermine-scripts/common/script_vars_common.sh

# Create log directory if it doesn't already exist
if [ ! -d "${log_dir}" ]; then
    mkdir ${log_dir}
fi

script_outfile="${log_dir}/${script_outfilename}"
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

#!/bin/bash 

# Variables common to intermine scripts
run_datetime=`date +%Y%m%d%H%M`
script_base=`basename "$0"`
script_name=${script_base%.*}
script_outfilename="${mine_name}_${script_name}_${run_datetime}.out"

mine_base_dir=$(find /db -mindepth 1 -maxdepth 1 -type d -name "*mine*")
mine_logs_dir="${mine_base_dir}/logs"
build_dir="${mine_logs_dir}/build_out"
mine_basename=$(grep "webapp.path" ~/.intermine/*.properties | tail -n 1 | awk -F'=' '{print $2}')
mine_home_dir="${mine_base_dir}/intermine/${mine_basename}"

mail_subj="Intermine script"
mail_msg="Intermine script ${script_base}"
notify_email=$MY_EMAIL

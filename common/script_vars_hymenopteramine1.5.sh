#!/bin/bash 

# Variables common to intermine scripts
run_datetime=`date +%Y%m%d%H%M`

script_base=`basename "$0"`
script_name=${script_base%.*}
log_dir="$HOME/intermine_scripts/logs"
script_outfile="${log_dir}/${script_name}_${run_datetime}.out"

mine_base_dir="/db/hymenopteramine_v1.5"
mine_logs_dir="${mine_base_dir}/logs"
build_dir="${mine_logs_dir}/build_out"
mine_home_dir="${mine_base_dir}/intermine/hymenopteramine"

mail_subj="Intermine script"
mail_msg="Intermine script ${script_base}"
notify_email="walshamy@missouri.edu"


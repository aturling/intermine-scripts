#!/bin/bash 

# Variables common to intermine scripts
run_datetime=`date +%Y%m%d%H%M`

mine_name="maizemine"
script_base=`basename "$0"`
script_name=${script_base%.*}
log_dir="$HOME/intermine-scripts/loading_v4/log"
script_outfile="${log_dir}/${mine_name}_${script_name}_${run_datetime}.out"

mine_base_dir="/db/maizemine_v1.4"
mine_logs_dir="${mine_base_dir}/logs"
build_dir="${mine_logs_dir}/build_out"
mine_home_dir="${mine_base_dir}/intermine/maizemine"

mail_subj="Intermine script"
mail_msg="Intermine script ${script_base}"
notify_email="walshamy@missouri.edu"

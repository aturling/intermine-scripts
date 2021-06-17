#!/bin/bash  

########################################################
# generate_postprocess_lines_for_script.sh
#
# This script gets the postprocess names from project.xml and
# generates the command lines that can then be
# pasted into the postprocess script, possibly with some
# postgres restarts in between at various points.
########################################################

scriptname=`basename "$0"`

if [ $# -eq 0 ]; then
    echo "Usage  : ./${scriptname} <variables_file_location>"
    echo "Example: ./${scriptname} ~/intermine-scripts/common/script_vars_faangmine1.2.sh"
    exit 1
fi

# variables
variablesfile=$1

# Source variables file
. $variablesfile

# location of project.xml file
projectxmlfile="${interminedir}/project.xml"

# call perl script that parses project.xml and gets list of source names
perl get_postprocess_names.pl $projectxmlfile | sed 's/^/postprocess_with_exit_on_error "/' | sed 's/$/" >> $outfile/'

# old way: what if source is commented out??? need to actually parse xml 
# one-liner that gets the source names and adds the command text
#grep "source name=" ${projectxmlfile} | awk '{ print $2 }' | awk -F"=" '{ print $2 }' | awk -F'"' '{ print $2 }' | sed 's/^/load_source_with_exit_on_error "/' | sed 's/$/" >> $outfile/'

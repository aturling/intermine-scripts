#!/bin/bash  

#####################################################
# check_files_and_dirs_in_projectxml.sh
#
# This script quickly checks that all files and
# directories referred to in project.xml (that are not
# commented out) actually exist.
#####################################################

scriptname=`basename "$0"`

# variables
. ~/intermine-scripts/common/script_vars_common.sh

# location of project.xml file
projectxmlfile="${mine_home_dir}/project.xml"

# call perl script that parses project.xml and gets list of directory and filenames
perl get_files_and_dir_names.pl $projectxmlfile > tmpnames.txt

# loop over directory and filenames list and check for existence of each
while read name; do
    if echo x"$name" | grep '*' > /dev/null; then
        echo "Filenames contain glob: $name"
    elif [ -d "$name" ]; then
        # Is a directory and exists, check if it's nonempty:
        if [ ! -n "$(ls -A $name 2>/dev/null)" ]; then
            echo "WARNING: directory $name is empty!"
        fi
    elif [ -f "$name" ]; then
        if [ ! -s "$name" ]; then
            echo "Warning: file $name exists but is empty!"
        fi
    else
        echo "WARNING: $name does not exist"
    fi
done < tmpnames.txt

# Delete tmp file
rm tmpnames.txt

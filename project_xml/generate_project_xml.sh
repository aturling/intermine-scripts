#!/bin/bash

#######################################################
# generate_project_xml.sh
#
# Generate project.xml entries from datasets directory
#######################################################

function add_sources {
    # Begin sources tag
    echo "  <sources>" >> $outfile
    echo >> $outfile

    # Mine-specific sources
    add_mine_sources

    # End sources tag
    echo "  </sources>" >> $outfile
    echo >> $outfile
}

function add_post_processes {
    # Begin post-processing tag
    echo "  <post-processing>" >> $outfile
    echo >> $outfile

    # Mine-specific postprocesses
    add_mine_post_processes

    # End post-processing tag
    echo "  </post-processing>" >> $outfile
    echo >> $outfile
}

functionsfile="project_xml_functions.sh"
. $functionsfile

# Get basic variables (mine name, etc.)
# Exit script early if these fail - cannot create project.xml
mine_name=$(get_mine_name)
ec=$?
if [ $ec -ne 0 ]; then
    exit 1
fi
mine_dir=$(get_mine_dir)
ec=$?
if [ $ec -ne 0 ]; then
    exit 1
fi
source_version=$(get_bio_source_version)
ec=$?
if [ $ec -ne 0 ]; then
    exit 1
fi

sourcesfile="${mine_name}/sources.sh"
. $sourcesfile

run_datetime=`date +%Y%m%d%H%M`
outdir="${mine_name}/output"
outfile="${outdir}/project_${run_datetime}.xml"

if [ ! -d "${outdir}" ]; then
    mkdir ${outdir}
fi

echo
echo "Output will be stored in $outfile"

# Init outfile
touch $outfile

# Add file headers
add_headers

# Add sources
add_sources

# Add postprocesses
add_post_processes

# Add end of file
add_footers

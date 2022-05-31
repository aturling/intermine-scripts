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

mine_name=$(get_mine_name)
mine_dir=$(get_mine_dir)
source_version=$(get_bio_source_version)

sourcesfile="${mine_name}/sources.sh"
. $sourcesfile

run_datetime=`date +%Y%m%d%H%M`
outdir="${mine_name}/output"
outfile="${outdir}/project_${run_datetime}.xml"

if [ ! -d "${outdir}" ]; then
    mkdir ${outdir}
fi

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

#!/bin/bash

#######################################################
# get_feature_parent_types_from_gffs
#
# Given a feature type as input, get its parent type(s)
#
# TODO: not finished
#######################################################

scriptname=`basename "$0"`
if [ $# -eq 0 ]; then
    echo "Usage  : ./${scriptname} <feature_type>"
    echo "Example: ./${scriptname} miRNA"
    echo "Note: <feature_type> is case-sensitive!"
    exit 1
fi

# Input feature type
feature_type=$1

# Temp dir
tmpdir="temp"
if [ ! -d "${tmpdir}" ]; then
    mkdir ${tmpdir}
fi
# Clear out from a previous run
rm -f ${tmpdir}/*

minedir=$(find /db -mindepth 1 -maxdepth 1 -type d -name "*mine*")

echo

sources=("RefSeq" "Ensembl" "MaizeGDB" "Genbank")
for source in "${sources[@]}" ; do
    echo "Source: $source"
    echo "-------------------"
    # Iterate over species dirs
    dirs=$(find ${minedir}/datasets/${source}/annotations -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
    for dir in $dirs; do
        fullname=$(echo "$dir" | sed 's/_/ /'g)
        echo "Organism: ${fullname^}"
        outfile="${tmpdir}/${dir}_${source}.out"
        touch $outfile
        line_count=0
        total_line_count=$(wc -l ${minedir}/datasets/RefSeq/annotations/${dir}/*/genes/*.gff3 | tail -n 1 | awk '{print $1}')
        no_parent_count=0
        #echo "Total number of lines: $total_line_count"
        grep -rsP "\t${feature_type}\t" ${minedir}/datasets/${source}/annotations/${dir}/*/genes/ | while read -r line ; do
            # Get parent ID
            parent_id=$(echo "$line" | grep -oE "Parent=[^;]*" | awk -F'=' '{print $2}')
            #echo "Parent ID is: $parent_id"
            if [ -z $parent_id ]; then
                #echo "No parent found"
                no_parent_count=$((no_parent_count+1))
            else
                # Get parent type
                parent_type=$(grep -rs "ID=${parent_id};" ${minedir}/datasets/${source}/annotations/${dir}/*/genes | awk '{print $3}')
                #echo "Parent type is: $parent_type"
                echo "$parent_type" >> $outfile
            fi

            let "line_count++"
            #if [ "$line_count" -eq 5 ]; then
            if (( $line_count % 100000 == 0)); then
                echo "Processed $line_count lines of $total_line_count"
                #break 1;
            fi
        done
        if [ -s "$outfile" ]; then
            types=$(cat $outfile | sort | uniq | xargs)
            echo "Parent type(s) for ${fullname^} ($source): $types"
            echo "Number of $dir features with no parent: $no_parent_count"
        else
            echo "${feature_type} not found in file"
        fi
        echo
    done
    echo
    all_types=$(cat ${tmpdir}/* | sort | uniq | xargs)
    echo "All parent type(s): $all_types"
done

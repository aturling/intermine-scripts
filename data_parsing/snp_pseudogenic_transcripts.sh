#!/bin/bash

# Replace 'transcript' with 'pseudogenic_transcript' in SNP files if id shows up in
# datasets/Ensembl/annotations/*/*/pseudogenes
# Input file: list of all pseudogenic_transcript ids

scriptname=`basename "$0"`
if [ $# -eq 0 ]; then
    echo "Usage  : ./${scriptname} <full path to directory with transcript ids>"
    echo "Example: ./${scriptname} ~/pseudogenic_transcript_ids.txt"
    exit 1
fi

# Iterate over all SNP files
while read transcript_id; do
    echo "Looking for $transcript_id"
    vcf_files=$(find /db/*/datasets/SNP-test/ -type f -name "*.vcf")
    for vcf_file in $vcf_files; do
        #echo "${vcf_file}:"
        if grep -q "|transcript|$transcript_id" $vcf_file; then
            echo "Running sed -i 's/transcript|${transcript_id}/pseudogenic_transcript|${transcript_id}/g' $vcf_file"
            sed -i "s/transcript|${transcript_id}/pseudogenic_transcript|${transcript_id}/g" "$vcf_file"
        fi 
    done
done <$1

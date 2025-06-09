#!/bin/bash

# Replace 'transcript' with 'pseudogenic_transcript' in SNP files if id shows up in
# datasets/Ensembl/annotations/*/*/pseudogenes
# Input file: list of all pseudogenic_transcript ids

scriptname=`basename "$0"`
if [ $# -lt 2 ]; then
    echo "Usage  : ./${scriptname} <full path to directory with transcript ids> <organism_directory_name>"
    echo "Example: ./${scriptname} ~/pseudogenic_transcript_ids.txt bos_taurus"
    exit 1
fi

# Iterate over all SNP files
while read transcript_id; do
    echo "Looking for $transcript_id"
    vcf_files=$(find /db/*/datasets/SNP/Ensembl/$2 -type f -name "*.vcf")
    for vcf_file in $vcf_files; do
        #echo "${vcf_file}:"
        if grep -q "|primary_transcript|$transcript_id" $vcf_file; then
            echo "Running sed -i 's/|primary_transcript|${transcript_id}/|pseudogenic_transcript|${transcript_id}/g' $vcf_file"
            sed -i "s/|primary_transcript|${transcript_id}/|pseudogenic_transcript|${transcript_id}/g" "$vcf_file"
        fi
        if grep -q "|transcript|$transcript_id" $vcf_file; then
            echo "Running sed -i 's/|transcript|${transcript_id}/|pseudogenic_transcript|${transcript_id}/g' $vcf_file"
            sed -i "s/|transcript|${transcript_id}/|pseudogenic_transcript|${transcript_id}/g" "$vcf_file"
        fi
        if grep -q "ncRNA|$transcript_id" $vcf_file; then
            echo "Running sed -i 's/|ncRNA|${transcript_id}/|pseudogenic_transcript|${transcript_id}/g' $vcf_file"
            sed -i "s/|ncRNA|${transcript_id}/|pseudogenic_transcript|${transcript_id}/g" "$vcf_file"
        fi
    done
done <$1

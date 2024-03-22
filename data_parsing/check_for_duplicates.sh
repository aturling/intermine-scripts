#!/bin/bash

# Check for duplicates in sources where duplicate ids would cause a loading error

# Ensembl Compara / Biomart symbols and descriptions

dupes_found=0
if [[ $(find /db/*/datasets -type d -name ensembl-plant-biomart) ]]; then
    echo "Checking ensembl-plant-biomart symbols and descriptions..."
    tab_files=$(find /db/*/datasets/ensembl-plant-biomart -type f -name "*.tab")
    for tab_file in $tab_files; do
        num_dupes=$(sort $tab_file | uniq -c | awk '{print $1}' | grep -v '^1$' | wc -l)
        if [ "$num_dupes" -gt 0 ]; then
            echo "WARNING: Duplicate ids found in file: $tab_file"
            dupes_found=1
        fi
    done
else
    echo "Ensembl-plant-biomart data directory not found"
fi

if [ "$dupes_found" -eq 0 ]; then
    echo "No duplicate ids found"
fi

# GFF files - IDs should be unique across gff source (dir)

# Iterate over all GFF files
echo "Checking gff files..."
dupes_found=0
gff_dirs=$(find /db/*/datasets/ -type f -name "*.gff*" -exec dirname {} \;)
for gff_dir in $gff_dirs; do
    num_dupes=$(cat $gff_dir/*gff* | cut -f9 | grep -oE '[^_]?ID=[^;]*' | sort | uniq -c | awk '{print $1}' | grep -vE '^1$' | wc -l)
    if [ "$num_dupes" -gt 0 ]; then
        echo "WARNING: Duplicate ids found in gff dir: $gff_dir"
        dupes_found=1
    fi
done

if [ "$dupes_found" -eq 0 ]; then
    echo "No duplicate ids found"
fi

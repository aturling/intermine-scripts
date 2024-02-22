#!/bin/bash

# Check GFF last column for PubMed IDs
# They are normally not loaded with the standard GFF loader, but we do load them with the QTL loader, for example
# However the loader expects the tag to have the form: PUBMED_ID=<pubmedid>

# Iterate over all GFF files
echo "Checking gff files..."
gff_files=$(find /db/*/datasets/ -type f -name "*.gff*")
for gff_file in $gff_files; do
    result=$(grep -m 1 -ioE "pubmed.*=[0-9]+" $gff_file | awk -F'=' '{print $1}')
    if [ ! -z "$result" ]; then
        # Check that format is correct so that loader will pick it up
        if [ "$result" != "PUBMED_ID" ]; then
            echo "WARNING: Found \"$result\" in $gff_file - incorrect format!"
            echo "Run this command:"
            echo "sed -i 's/$result=/PUBMED_ID=/g' $gff_file"
        else
            echo "Found \"$result\" in $gff_file - check that this type of loader parses publications"
        fi
    fi
done

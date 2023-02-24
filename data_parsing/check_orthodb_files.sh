#!/bin/bash

# Verify that files are in the correct format for OrthoDB loader

scriptname=`basename "$0"`
if [ $# -eq 0 ]; then
    echo "Usage  : ./${scriptname} <full path to directory with OrthoDB files>"
    echo "Example: ./${scriptname} /db/hymenopteramine_v1.6/datasets/OrthoDB"
    exit 1
fi

dirname=$1
ec=0

echo "Checking files in $dirname"
echo

# Check for missing taxon ids
echo "Checking for missing taxon IDs..."
# Should return 0 (i.e., no taxon ids missing):
num_missing_taxon_ids=$(awk -F'\t' '{print $6}' ${dirname}/* | sort | uniq | grep -vE '[0-9]+' | wc -l)
if [ "$num_missing_taxon_ids" -ne 0 ]; then
    echo "WARNING: At least one file in $dirname has missing taxon IDs" 1>&2
    ec=1
else
    echo "No missing taxon IDs"
fi
echo

# Check for singleton clusters
echo "Checking for singleton clusters..."
# Should not return anything:
has_singleton_clusters=$(awk '{print $2}' ${dirname}/* | uniq -c | sort -n | awk '{print $1}' | uniq -c | head -n 1 | grep ' 1')
if [ ! -z "$has_singleton_clusters" ]; then
   echo "WARNING: At least one file in $dirname has singleton cluster(s)" 1>&2
   ec=1
else
   echo "No singleton clusters found"
fi
echo

# Check for duplicates within a cluster/LCA
echo "Checking for duplicates within a cluster and LCA..."
# Should return 1 (i.e., all unique, no duplicates) 
num_duplicates=$(awk '{print $2 "|" $3 "|" $7 "|" $8 }' ${dirname}/* | sort | uniq -c | awk '{print $1}' | sort -n | uniq -c | wc -l)
if [ "$num_duplicates" -ne 1 ]; then
    echo "WARNING: At least one file in $dirname contains duplicates within a cluster and LCA" 1>&2
    ec=1
else
    echo "No duplicates found"
fi

exit $ec

#!/bin/bash

#infile="/db/hymenopteramine_v1.5/datasets/Orthodb/final/ODBv10.1_parsed_final_combined_20200911_sorted_without_singles_or_dups.tab"
infile=$1

last_clusterid=0
cluster_count=0
total_count=0
line_count=0

# Get first cluster id
last_clusterid="$(head -n 1 $infile | awk '{print $2}')"

while IFS= read -r line; do
    let "line_count++"

    if ! (( $line_count % 10000 )) ; then
        echo "Processed $line_count lines"
    fi

    cluster_id="$(echo $line | awk '{print $2}')"

    if [ "$cluster_id" != "$last_clusterid" ]; then
        # We're in the next cluster, total up values from previous cluster
        #echo "There were ${cluster_count} elements in cluster ${cluster_id}"
        total_count=$((total_count + cluster_count*(cluster_count-1)))
        #echo "Total homologue count is now ${total_count}"

        # Reset cluster count
        cluster_count=0
    fi

    let "cluster_count++"
    last_clusterid=$cluster_id
done < $infile

# Process last homologue cluster
echo "There were ${cluster_count} elements in cluster ${last_clusterid}"
total_count=$((total_count + cluster_count*(cluster_count-1)))
echo "Total homologue count is ${total_count}"

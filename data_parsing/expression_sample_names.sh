#!/bin/bash

# Check that expression/experiment names agree with metadata file

mine_basename=$(grep "webapp.path"  ~/.intermine/*.properties | tail -n 1 | awk -F'=' '{print $2}')
expr_dir="gene_expression"
metadata_dir="experiment"
col_name="Experiment"

if [ "$mine_basename" == "maizemine" ]; then
  expr_dir="expression"
  metadata_dir="expression/metadata"
  col_name="Sample_ID"
fi

# First get the sample names from the expression files
# Iterate over organisms
orgs=$(find /db/*/datasets/${expr_dir} -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | grep '_' | sort)
for org in $orgs; do
  # Iterate over sources
  sources=$(find /db/*/datasets/${expr_dir}/${org} -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
  for sourcedir in $sources; do
    # For each expression file, get the sample names from the header
    expr_files=$(find /db/*/datasets/${expr_dir}/${org}/${sourcedir} -mindepth 1 -maxdepth 1 -type f)
    for expr_file in $expr_files; do
      # Store sample names in temp file #1
      head -n 1 "$expr_file" | tr '\t' '\n' | grep -v "Gene" >> sample_names-1.txt
    done
  done
done

sort sample_names-1.txt | uniq > sample_names-1-sorted.txt
rm sample_names-1.txt

# Next get the sample names from the metadata file
metadata_file=$(find /db/*/datasets/${metadata_dir} -mindepth 1 -maxdepth 1 -type f)
col_number=$(awk -v RS='\t' "/$col_name/{print NR; exit}" "$metadata_file")
cut -f"$col_number" "$metadata_file" | grep -v "$col_name" > "sample_names-2.txt"

sort sample_names-2.txt | uniq > sample_names-2-sorted.txt
rm sample_names-2.txt

# Lastly, compare the files - they should be the same!
files_not_same=$(diff sample_names-1-sorted.txt sample_names-2-sorted.txt | wc -l)
if [ "$files_not_same" -gt 0 ]; then
  echo "ERROR: the expression/experiment names in the data files and metadata file do not agree!"
  echo
  echo "Number of mismatches: $files_not_same"
  echo
  echo "Actual names that disagree:"
  diff sample_names-1-sorted.txt sample_names-2-sorted.txt
else
  echo "No errors found with the expression/experiment names"
fi

# Clean up
rm sample_names-1-sorted.txt
rm sample_names-2-sorted.txt

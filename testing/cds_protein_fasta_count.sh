#!/bin/bash  

#######################################################
# cds_protein_fasta_count.sh
#
# Check database for correct number of coding sequences
# and polypeptides.
#######################################################

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

all_counts_correct=1

# CodingSequences:
echo "Checking CodingSequence counts..."
sources=("RefSeq" "Ensembl" "MaizeGDB" "Genbank")
for source in "${sources[@]}" ; do
    # First check if source exists for this mine
    srcdir=$(find /db/*/datasets/ -maxdepth 1 -type d -name "$source")
    if [ ! -z $srcdir ]; then
        echo "Source: $source..."
        files=$(find /db/*/datasets/${source}/cds_fasta* -type f -name *.fa)

        for fasta_file in $files; do
            # assumes directory format is /db/<mine_dir>/datasets/<source>/cds_fasta/<organism_name>/<assembly>/*.fa
            org_name=$(echo "${fasta_file}" | awk -F'/' '{print $7}' | sed 's/_/ /g')
            assembly=$(echo "${fasta_file}" | awk -F'/' '{print $8}')
            echo "Checking $source coding sequences for ${org_name} (assembly: $assembly)..."
            # get org id to make query faster
            org_id=$(psql ${dbname} -c "select o.id from organism o where lower(o.name)='${org_name}'" -t -A)
            if [ -z $org_id ]; then
               # Try using assembly version instead
               org_id=$(psql ${dbname} -c "select o.id from chromosome c join organism o on o.id=c.organismid where c.assembly='${assembly}' limit 1" -t -A)
            fi
            if [ -z $org_id ]; then
                # If still can't find it, skip to next organism
                echo "WARNING: organism $org_name not in database!"
                continue
            fi
            dbcount=$(psql ${dbname} -c "select count(c.id) from codingsequence c where c.source='$source' and c.organismid=${org_id}" -t -A)
            filecount=$(grep ">" $fasta_file | wc -l)
            if [ $dbcount -eq $filecount ]; then
                echo "CodingSequence count correct ($filecount)"
            else
                echo "WARNING: database has $dbcount CodingSequences but fasta file has $filecount!"
                all_counts_correct=0
            fi
        done
        echo
    fi
done
echo

# Polypeptides:
echo "Checking Polypeptide counts..."
for source in "${sources[@]}" ; do
    # First check if source exists for this mine
    srcdir=$(find /db/*/datasets/ -maxdepth 1 -type d -name "$source")

    if [ ! -z $srcdir ]; then
        echo "Source: $source..."
        files=$(find /db/*/datasets/${source}/protein_fasta* -type f -name *.fa)

        for fasta_file in $files; do
            # assumes directory format is /db/<mine_dir>/datasets/<source>/protein_fasta/<organism_name>/<assembly>/*.fa
            org_name=$(echo "${fasta_file}" | awk -F'/' '{print $7}' | sed 's/_/ /g')
            assembly=$(echo "${fasta_file}" | awk -F'/' '{print $8}')
            echo "Checking $source polypeptides for ${org_name} (assembly: $assembly)..."
            # get org id to make query faster
            org_id=$(psql ${dbname} -c "select o.id from organism o where lower(o.name)='${org_name}'" -t -A)
            if [ -z $org_id ]; then
               # Try using assembly version instead
               org_id=$(psql ${dbname} -c "select o.id from chromosome c join organism o on o.id=c.organismid where c.assembly='${assembly}' limit 1" -t -A)
            fi
            if [ -z $org_id ]; then
                # If still can't find it, skip to next organism
                echo "WARNING: organism $org_name not in database!"
                continue
            fi
            dbcount=$(psql ${dbname} -c "select count(p.id) from polypeptide p where p.source='$source' and p.organismid=${org_id}" -t -A)
            filecount=$(grep ">" $fasta_file | wc -l)
            if [ $dbcount -eq $filecount ]; then
                echo "Polypeptide count correct ($filecount)"
            else
                echo "WARNING: database has $dbcount polypeptides but fasta file has $filecount!"
                all_counts_correct=0
            fi
        done
        echo
    fi
done

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

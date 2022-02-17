#!/bin/bash  

#######################################################
# chromosome_count.sh
#
# Check database for correct number of chromosomes.
#######################################################

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

fasta_files=$(find /db/*/datasets/genome -name *.fa)

for fasta_file in $fasta_files; do
    # assumes directory format is /db/<mine_dir>/datasets/genome/<organism_name>/<assembly>/*.fa
    org_name=$(echo "${fasta_file}" | awk -F'/' '{print $6}' | sed 's/_/ /g')
    assembly=$(echo "${fasta_file}" | awk -F'/' '{print $7}')
    echo "Checking chromosomes for ${org_name} (assembly: $assembly)..."
    dbcount=$(psql ${dbname} -c "select count(c.id) from chromosome c where c.assembly='$assembly'" -t -A)
    filecount=$(grep '>' $fasta_file | wc -l)
    if [ $dbcount -eq $filecount ]; then
        echo "Chromosome count correct ($filecount)"
    else
        echo "WARNING: database has $dbcount chromosomes but fasta file has $filecount chromosomes!"
    fi
    echo
done

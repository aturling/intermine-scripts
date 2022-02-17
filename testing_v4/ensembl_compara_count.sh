#!/bin/bash  

#######################################################
# ensembl_compara_count.sh
#
# Check database for correct number of homologues from
# Ensembl Compara data set.
#######################################################

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Get number of homologues from Ensembl Compara per taxon ID
echo "Querying database for Ensembl Compara homologues..."
dataset_name="Ensembl Compara data set"
dbcount=$(psql ${dbname} -c "select count(h.id), o.taxonid from homologue h join datasetshomologue dh on dh.homologue = h.id join dataset d on d.id=dh.datasets join gene g on g.id=h.geneid join organism o on o.id=g.organismid where d.name='${dataset_name}' group by o.taxonid" -t -A)

for row in $dbcount; do
   h_count=$(echo "$row" | awk -F'|' '{print $1}')
   taxon_id=$(echo "$row" | awk -F'|' '{print $2}') 
   file_count=$(wc -l /db/*/datasets/EnsemblCompara/*${taxon_id}* | grep total | awk '{print $1}')
   if [ $h_count -eq $file_count ]; then
       echo "Chromosome count correct for organism with taxon id $taxon_id ($file_count homologues)"
   else
       echo "WARNING: database has $h_count homologues for organism with taxon id $taxon_id, files have $file_count homologues!"
   fi
   echo
done

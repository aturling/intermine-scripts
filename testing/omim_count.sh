#!/bin/bash  

#######################################################
# omim_count.sh
#
# Check database for correct number of OMIM diseases,
# genes, and publications.
#######################################################

section_divide="----------------------------------------------------------------"
all_counts_correct=1

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Get dataset id for OMIM to help simplify queries
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name like 'OMIM%'" -t -A)

# Check disease count
echo "Checking Disease count..."

# Store valid MIM numbers in a file because we'll refer to the list later
this_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$this_path"
if [ ! -d "temp" ]; then
    mkdir temp
fi
grep -vE '^#' /db/*/datasets/omim/mimTitles.txt | grep -vE '^Caret' | grep -vE '^Asterisk' | grep -vE '^Plus' | cut -f2 | sort -n | uniq > temp/mim_numbers.txt

file_count=$(wc -l < temp/mim_numbers.txt)
db_count=$(psql ${dbname} -c "select count(*) from disease" -t -A)
if [ ! $file_count -eq $db_count ]; then
    echo "WARNING: $file_count diseases in mimTitles.txt, but $db_count diseases in database!"
    all_counts_correct=0
else
    echo "Disease count correct ($db_count diseases)"
fi
echo

# Check publications
# Pubs only added to diseases found in mimTitles.txt
echo "Checking Publication count..."
# Get publications with an associated disease
db_count=$(psql ${dbname} -c "select count(distinct(p.pubmedid)) from publication as p join entitiespublications ep on ep.publications=p.id join disease d on d.id=ep.entities"  -t -A)
touch temp/pubs.txt
while read mim_number; do
    pub_lines=$(grep -E "^${mim_number}" /db/*/datasets/omim/pubmed_cited.txt | cut -f3)
    while IFS= read -r pub_id; do
        if [ ! -z "$pub_id" ]; then
            echo "$pub_id" >> temp/pubs.txt
        fi
    done <<< "$pub_lines"
done < temp/mim_numbers.txt
file_count=$(sort -n temp/pubs.txt | uniq | wc -l)
if [ ! $file_count -eq $db_count ]; then
    echo "WARNING: $file_count publications in pubmed_cited.txt, but $db_count publications in database!"
    all_counts_correct=0
else
    echo "Publication count correct ($db_count publications)"
fi

# TODO: Count genes?
# More difficult since involves ID resolver lookups

# clean up
rm temp/mim_numbers.txt
rm temp/pubs.txt
rmdir temp

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo


#!/bin/bash  

#######################################################
# duplicate_entities.sh
#
# Check database for duplicates (genes, proteins, etc.)
# Also check for null entries.
#######################################################

# Function to run database query for null fields in table
# Input args:
#   (1) database name
#   (2) table name of entity class (e.g., gene, protein)
#   (3) field name to count nulls (e.g., primaryidentifier, primaryaccession)
run_null_query() {
    dbname=$1
    tablename=$2
    fieldname=$3
    dbcount=$(psql ${dbname} -c "select count(id) from ${tablename} where ${fieldname} is null" -t -A)
    if [ ! $dbcount -eq 0 ]; then
        echo "WARNING: ${tablename} has ${dbcount} rows where ${fieldname} is null"
    else
        echo "No null values for ${fieldname}"
    fi
}

# Function to run database query for duplicate entities
# Input args:
#   (1) database name
#   (2) table name of entity class (e.g., gene, protein)
#   (3) field name of primary identifier (e.g., primaryidentifier, primaryaccession)
#   (4) whether to add orgs equal to query (1=yes, 0=no)
run_duplicate_dbquery () {
    dbname=$1
    tablename=$2
    fieldname=$3
    orgs_equal=$4
    if [ $orgs_equal -eq 0 ]; then
        orgs_equal=""
    else
        orgs_equal=" and t2.organismid = t1.organismid"
    fi
    count_ids_select="(select count(*) from ${tablename} t2 where t2.${fieldname} = t1.${fieldname}${orgs_equal}) > 1"
    echo "Checking for duplicate ${tablename}s..."
    #echo "Running: psql ${dbname} -c 'select count(${fieldname}), organismid from ${tablename} t1 where ${count_ids_select} group by organismid limit 1' -t -A"
    dbcount=$(psql ${dbname} -c "select count(${fieldname}), organismid from ${tablename} t1 where ${count_ids_select} group by organismid limit 1" -t -A)
    if [ ! -z $dbcount ]; then
        if [ ! -z $orgs_equal ]; then
            # If orgs equal included in query, duplicates definitely found
            echo "WARNING: duplicate ${tablename}s found!"
        else
            # If orgs not equal included, possible that these aren't actually duplicates, need to check
            id_list=$(psql ${dbname} -c "select ${fieldname} from ${tablename} t1 where ${count_ids_select}" -t -A)
            id_count=$(echo "${id_list}" | wc -l)
            echo "Possible duplicate ${tablename}s; checking ${id_count} individual identifiers..."
            total_dupe_ids=0
            for dupe_id in $id_list; do
                #echo "Checking ${dupe_id}"
                id_count=$(psql ${dbname} -c "select count(id) as c from ${tablename} where ${fieldname}='${dupe_id}' group by organismid order by c desc limit 1" -t -A)
                if [ ! $id_count -eq 1 ]; then
                    echo "WARNING: Duplicate ${tablename} found with identifier ${dupe_id}"
                    total_dupe_ids=$((total_dupe_ids + 1))
                fi
                if [ $total_dupe_ids -gt 10 ]; then
                    echo "More than 10 duplicate ${tablename}s found, query database for all duplicates."
                    break
                fi
            done
            if [ $total_dupe_ids -eq 0 ]; then
                echo "No duplicate ${tablename}s found"
            fi
        fi
    else
        echo "No duplicate ${tablename}s found"
    fi
    echo
}

section_divide="----------------------------------------------------------------"

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

#-------------------------------------
# sequence features
# (includes genes, chromosomes, etc.)
#-------------------------------------
echo "${section_divide}"
echo "Sequence features:"
echo
echo "Checking for null fields..."

# null IDs
run_null_query ${dbname} "sequencefeature" "primaryidentifier"

# null organism
run_null_query ${dbname} "sequencefeature" "organismid"
echo


#-------------
# chromosomes
#-------------

echo "${section_divide}"
echo "Chromosomes:"
echo
echo "Checking for null fields..."

# null IDs
run_null_query ${dbname} "chromosome" "secondaryidentifier"
run_null_query ${dbname} "chromosome" "tertiaryidentifier"
run_null_query ${dbname} "chromosome" "name"

# null assembly
run_null_query ${dbname} "chromosome" "assembly"

# duplicates
run_duplicate_dbquery ${dbname} "chromosome" "primaryidentifier" 1


#-------
# genes
#-------
echo "${section_divide}"
echo "Genes:"

# duplicates
run_duplicate_dbquery ${dbname} "gene" "primaryidentifier" 0

#-------------
# pseudogenes
#-------------
echo "${section_divide}"
echo "Pseudogenes:"

# duplicates
run_duplicate_dbquery ${dbname} "pseudogene" "primaryidentifier" 0


#-------
# mRNAs
#-------
echo "${section_divide}"
echo "mRNAs:"
echo
echo "Checking for null fields..."

# null IDs
run_null_query ${dbname} "mrna" "primaryidentifier"

# null organism
run_null_query ${dbname} "mrna" "organismid"

# duplicates
run_duplicate_dbquery ${dbname} "mrna" "primaryidentifier" 0


#------------------
# coding sequences
#------------------
echo "${section_divide}"
echo "Coding sequences:"
echo
echo "Checking for null fields..."

# null IDs
run_null_query ${dbname} "codingsequence" "proteinidentifier"
echo

#--------------
# polypeptides
#--------------
echo "${section_divide}"
echo "Polypeptides:"
echo

# duplicates
run_duplicate_dbquery ${dbname} "polypeptide" "primaryidentifier" 0


#----------------------------------
# proteins (not a sequencefeature)
#----------------------------------
echo "${section_divide}"
echo "Proteins:"
echo
echo "Checking for null fields..."

# null IDs
run_null_query ${dbname} "protein" "primaryaccession"

# null organism
run_null_query ${dbname} "protein" "organismid"

# empty sequences:
run_null_query ${dbname} "protein" "md5checksum"

# duplicates:
run_duplicate_dbquery ${dbname} "protein" "primaryaccession" 0

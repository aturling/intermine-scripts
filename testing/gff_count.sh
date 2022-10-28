#!/bin/bash  

#######################################################
# gff_count.sh
#
# Check database for correct number of entities loaded
# from gff files (genes, exons, transcripts, etc.)
#
# TODO: add pseudogenes
#######################################################

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

# Requires that entrez-organism loaded first
nullcount=$(psql ${dbname} -c "select count(*) from organism where name is null" -t -A)
if [ "$nullcount" -gt 0 ]; then
    echo "Entrez-organism source needs to be loaded before running this test!"
    # Exit early, nothing to do
    exit 1
fi

all_counts_correct=1

sources=("RefSeq" "Ensembl" "MaizeGDB" "OGS" "Genbank")
echo "Checking gff counts..."
echo
for source in "${sources[@]}" ; do
    echo "Source: $source"
    echo
    subdir=""
    if [[ "$source" == "RefSeq" ]] || [[ "$source" == "Ensembl" ]]; then
        subdir="genes/"
    fi
    # Iterate over all organisms/assemblies
    files=$(find /db/*/datasets/${source}/annotations/*/*/${subrdir} -type f -name *.gff3 2>/dev/null)
    for file in $files; do
        org_dir=$(echo "${file}" | awk -F'/' '{print $7}')
        org_name=$(echo "$org_dir" | sed 's/_/ /g')
        assembly=$(echo "${file}" | awk -F'/' '{print $8}')

        # Usually just one genesource per org but nasonia vitripennis has two for OGS:
        genesources=()
        append_dir=""
        if [[ "$org_dir" == "nasonia_vitripennis" ]] && [[ "$source" == "OGS" ]] ; then
           nvit_sources=$(find /db/*/datasets/$source/annotations/${org_dir}/${assembly}/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
           for nvit_source in $nvit_sources; do
               genesource=$(tail -n 1 /db/*/datasets/$source/annotations/${org_dir}/${assembly}/${nvit_source}/*.gff3 | cut -f2)
               genesources+=("$genesource")
           done
           append_dir="*/"
        else
            genesource="$source"
            # Special cases where Gene.source is not the same as the folder name
            if [[ "$source" == "MaizeGDB" ]] || [[ "$source" == "OGS" ]] ; then
                genesource=$(tail -n 1 /db/*/datasets/$source/annotations/${org_dir}/${assembly}/*.gff3 | cut -f2)
            fi
            genesources=("$genesource")
        fi

        for genesource in "${genesources[@]}" ; do
            echo "Checking $source ($genesource) gff for $org_name (assembly: $assembly)..."
      
            # Get org id in database
            org_id=$(psql ${dbname} -c "select o.id from organism o where lower(o.name)='${org_name}'" -t -A)
            if [ -z $org_id ]; then
                # Try using assembly version instead
                org_id=$(psql ${dbname} -c "select o.id from chromosome c join organism o on o.id=c.organismid where c.assembly='${assembly}' limit 1" -t -A)
            fi
            if [ -z $org_id ]; then
                # If still can't find it, skip to next organism
                echo "WARNING: organism $org_name not in database!"
                echo
                continue
            fi

            # Get all possible class names (transcripts, genes, etc.)
            echo "Getting all class names in input file..."
            classes=$(cat /db/*/datasets/${source}/annotations/*/${assembly}/${subdir}/${append_dir}*.gff3 | grep -v "#" | cut -f 3 | sort | uniq)
            echo $classes
            class_count_correct=1
            for class in $classes; do
                # Get database table name from class
                tablename=$(echo "$class" | sed 's/[^ _]*/\u&/g' | sed 's/_//g')
                # Count in database
                dbcount=0
                # Special case: gene
                if [ "$class" == "gene" ]; then
                    dataset_title_part="${genesource} gene set"
                    if [ "$source" == "OGS" ]; then
                        dataset_title_part="Official Gene Set ($genesource)"
                    fi
                    dbcount=$(psql ${dbname} -c "select count(g.id) from gene g join bioentitiesdatasets bed on bed.bioentities=g.id join dataset d on d.id=bed.datasets where g.organismid=${org_id} and g.source='${genesource}' and d.name like '%${dataset_title_part}%'" -t -A)
                else
                    dbcount=$(psql ${dbname} -c "select count(t.id) from $tablename t where t.organismid=${org_id} and t.source='${genesource}' and t.class='org.intermine.model.bio.${tablename}'" -t -A)
                fi
                filecount=$(cat /db/*/datasets/${source}/annotations/*/${assembly}/${subdir}/${append_dir}*.gff3 | grep -v "#" | cut -f 3 | grep -E "^${class}" | wc -l)
                if [ ! $dbcount -eq $filecount ]; then
                    echo "WARNING: $dbcount ${class}s in database, but $filecount in input file!"
                    class_count_correct=0
                    all_counts_correct=0
                fi
            done
            if [ ! $class_count_correct -eq 0 ]; then
                echo "Counts correct for all class names"
            fi
        done
        echo
    done
done

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

#!/bin/bash  

#######################################################
# faang_metadata_count.sh
#
# Check database for correct number of entities loaded
# from faang metadata files.
#######################################################

function get_cols {
    # See: https://unix.stackexchange.com/a/304320
    sed 's/\t/\n/g;q' $1 | nl -ba
}

function get_col_num {
    filename=$1
    colname=$2
    get_cols $filename | grep "$colname" | cut -f1 | xargs
}

function check_unique_field {
    tablename=$1
    fieldname=$2
    itemscount=$(psql ${dbname} -c "select count(${fieldname}) from $tablename t1 where (select count(*) from $tablename t2 where t2.${fieldname}=t1.${fieldname})> 1" -t -A)   
    if [ ! $itemscount -eq 0 ]; then
        echo "WARNING: $itemscount duplicate primary identifiers in $tablename"
        all_counts_correct=0
    else
        echo "No duplicate primary identifiers in $tablename"
    fi
}

function check_null_field {
    tablename=$1
    fieldname=$2
    fieldtype=$3
    null_items=$(psql ${dbname} -c "select count(id) from ${tablename} where ${fieldname} is null" -t -A)
    if [ ! $null_items -eq 0 ]; then
        echo "WARNING: $null_items $tablename rows with no $fieldtype in database!"
        all_counts_correct=0
    else
        echo "$tablename ${fieldtype}s set correctly"
    fi
}

# get database name from properties file
dbname=$(grep db.production.datasource.databaseName ~/.intermine/*.properties | awk -F'=' '{print $2}')

echo "Database name is ${dbname}"
echo

all_counts_correct=1

echo "Checking BioProjects..."

# Get dataset id for bioprojects to help simplify queries
dataset_name="BioProject metadata data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "ERROR: BioProject metadata data set not found in database"
    dataset_id=0
fi

# Check number of bioprojects in database
# Each line in file is unique bioproject so count number of lines (minus header)
filecount=$(tail -n +2 /db/*/datasets/FAANG-bioproject/bioproject.txt | wc -l)
dbcount=$(psql ${dbname} -c "select count(b.id) from bioproject b join bioprojectdatasets bd on bd.bioproject=b.id where bd.datasets=${dataset_id}" -t -A)
if [ ! "$dbcount" -eq "$filecount" ]; then
    echo "WARNING: $dbcount BioProjects in database, but $filecount in input file!"
    all_counts_correct=0
else
    echo "BioProject count correct ($dbcount BioProjects)"
fi

# Check that unique identifier is really unique
check_unique_field "BioProject" "bioprojectuniqueid"

# Check that organism ref was set
check_null_field "BioProject" "organismid" "organism ref"

# Check that category is never empty
check_null_field "BioProject" "category" "category name"

# Check publications count
# Get column number of publication ids
col_num=$(get_col_num "/db/*/datasets/FAANG-bioproject/bioproject.txt" "PMID")
filecount=$(cut -f $col_num /db/*/datasets/FAANG-bioproject/bioproject.txt | grep -v PMID | grep -v '-' | sort | uniq | wc -l)
dbcount=$(psql ${dbname} -c "select count(distinct(publications)) from bioprojectpublications" -t -A)
if [ ! "$dbcount" -eq "$filecount" ]; then
    echo "WARNING: $dbcount BioProject publication refs in database, but $filecount in input file!"
    all_counts_correct=0
else
    echo "BioProject publication ref count correct ($dbcount Publications)"
fi

echo
echo "Checking BioSamples..."

# Get dataset id for biosamples to help simplify queries
dataset_name="BioSample metadata data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "ERROR: BioSample metadata data set not found in database"
    dataset_id=0
fi

# Check number of biosamples in database from biosamples file
# Each line in file is unique biosample so count number of lines (minus header)
filecount=$(tail -n +2 /db/*/datasets/FAANG-biosample/biosample.txt | wc -l)
dbcount=$(psql ${dbname} -c "select count(b.id) from biosample b join biosampledatasets bd on bd.biosample=b.id where bd.datasets=${dataset_id}" -t -A)
if [ ! "$dbcount" -eq "$filecount" ]; then
    echo "WARNING: $dbcount BioSamples in database, but $filecount in input file!"
    all_counts_correct=0
else
    echo "BioSample count correct ($dbcount BioSamples)"
fi

# Check that unique identifier is really unique
check_unique_field "BioSample" "biosampleid"

# Check that organism ref was set
check_null_field "BioSample" "organismid" "organism ref"

# Check ontologies
ontologies=(
    "ATOL|PhysiologicalConditionOwlatolID|animaltraitontologyforlivestockid"
    "BTO|btoID|brendatissueontologyid"
    "CL|CellTypeClID|cellontologyid"
    "EOL|EnvironmentalConditionsOwleolID|environmentontologyforlivestockid"
    "EFO|DevelopmentalStageEfoID|experimentalfactorontologyid"
    "HsapDv|DevelopmentalStageHsapdvID|humandevelopmentalstagesontologyid"
    "HP|HealthStatusAtCollectionHpID|humanphenotypeontologyid"
    "LBO|BreedLboID|livestockbreedontologyid"
    "MONDO|HealthStatusAtCollectionMondoID|mondodiseaseontologyid"
    "OBI|MaterialObiID|ontologyforbiomedicalinvestigationsid"
    "PATO|HealthStatusAtCollectionPatoID|phenotypeandtraitontologyid"
)
for key in "${ontologies[@]}"; do
    term=$(echo $key | cut -d'|' -f1)
    colname=$(echo $key | cut -d'|' -f2)
    fieldname=$(echo $key | cut -d'|' -f3)
    # get column number
    col_num=$(get_col_num "/db/*/datasets/FAANG-biosample/biosample.txt" "$colname")
    # count number of refs (non-distinct)
    dbcount=$(psql ${dbname} -c "select count(o.identifier) from biosample s join ${term}term o on o.id=s.${fieldname}" -t -A)
    filecount=$(tail -n +2 /db/*/datasets/FAANG-biosample/biosample.txt | cut -f $col_num | grep -v '-' | wc -l)
    if [ ! "$dbcount" -eq "$filecount" ]; then
        echo "WARNING: $dbcount BioSample $term term refs in database, but $filecount in input file!"
        all_counts_correct=0
    else
        echo "BioSample $term term ref count correct ($dbcount terms)"
    fi
    # count distinct
    dbcount=$(psql ${dbname} -c "select count(distinct(o.identifier)) from biosample s join ${term}term o on o.id=s.${fieldname}" -t -A)
    filecount=$(tail -n +2 /db/*/datasets/FAANG-biosample/biosample.txt | cut -f $col_num | grep -v '-' | sort | uniq | wc -l)
    if [ ! "$dbcount" -eq "$filecount" ]; then
        echo "WARNING: $dbcount BioSample distinct $term term refs in database, but $filecount in input file!"
        all_counts_correct=0
    else
        echo "BioSample distinct $term term ref count correct ($dbcount distinct terms)"
    fi
done
ontologycollections=(
    "Orphanet|orphanetrarediseaseontology|orphanetrarediseaseontologysamples"
    "UBERON|uberanatomyontology|samplesuberanatomyontology"
)
for key in "${ontologycollections[@]}"; do
    term=$(echo $key | cut -d'|' -f1)
    tablefield=$(echo $key | cut -d'|' -f2)
    tablename=$(echo $key | cut -d'|' -f3)
    # count number in collection (non-distinct)
    dbcount=$(psql ${dbname} -c "select count(*) from ${tablename}" -t -A)
    filecount=0
    while IFS= read line; do
        linecount=$(echo "$line" | grep -oE "${term}:[a-zA-Z0-9]+" | sort | uniq | wc -l)
        filecount=$((filecount + linecount))
    done < /db/*/datasets/FAANG-biosample/biosample.txt
    #filecount=$(grep -oE "${term}:[a-zA-Z0-9]+" /db/*/datasets/FAANG-biosample/biosample.txt | wc -l)
    # Have to count per line because each term is only stored once per sample id (but some lines have duplicate term ids
    # in different columns)
    if [ ! "$dbcount" -eq "$filecount" ]; then
        echo "WARNING: $dbcount BioSample collection of $term terms in database, but $filecount in input file!"
        all_counts_correct=0
    else
        echo "BioSample collection of $term term count correct ($dbcount terms)"
    fi
    # count distinct
    dbcount=$(psql ${dbname} -c "select count(distinct($tablefield)) from ${tablename}" -t -A)
    filecount=$(grep -oE "${term}:[a-zA-Z0-9]+" /db/*/datasets/FAANG-biosample/biosample.txt | sort | uniq | wc -l)
    if [ ! "$dbcount" -eq "$filecount" ]; then
        echo "WARNING: $dbcount BioSample collection of distinct $term terms in database, but $filecount in input file!"
        all_counts_correct=0
    else
        echo "BioSample collection of distinct $term term count correct ($dbcount terms)"
    fi
done

# Check biosample pools
dbcount=$(psql ${dbname} -c "select count(*) from biosamplepoolscomponentsampleids" -t -A)
col_num=$(get_col_num "/db/*/datasets/FAANG-biosample/biosample.txt" "BiosampleComponents")
filecount=$(cut -f $col_num /db/*/datasets/FAANG-biosample/biosample.txt | grep -v '-' | grep -oE "SAM[A-E0-9]+" | sort | uniq | wc -l)
if [ ! "$dbcount" -eq "$filecount" ]; then
    echo "WARNING: $dbcount BioSample pool ids in database, but $filecount in input file!"
    all_counts_correct=0
else
    echo "BioProject pool id count correct ($dbcount pool ids)"
fi

echo
echo "Checking Analyses..."

# Check number of analyses in database
# Each line in file is unique analysis so count number of lines (minus header)
filecount=$(tail -n +2 /db/*/datasets/FAANG-analysis/analysis.txt | wc -l)
dbcount=$(psql ${dbname} -c "select count(id) from analysis" -t -A)
if [ ! "$dbcount" -eq "$filecount" ]; then
    echo "WARNING: $dbcount Analyses in database, but $filecount in input file!"
    all_counts_correct=0
else
    echo "Analysis count correct ($dbcount Analyses)"
fi

# Check that organism ref was set
check_null_field "Analysis" "organismid" "organism ref"

# Check that source is never empty
check_null_field "Analysis" "source" "source name"

# Check that biosample ref was set
check_null_field "Analysis" "biosampleid" "BioSample ref"

# Check that bioproject ref was set
check_null_field "Analysis" "bioprojectid" "BioProject ref"

# Check experiments count
col_num=$(get_col_num "/db/*/datasets/FAANG-analysis/analysis.txt" "ExperimentAccession")
filecount=$(cut -f $col_num /db/*/datasets/FAANG-analysis/analysis.txt | grep -v ExperimentAccession | grep -v '-' | grep -oE "[A-Z0-9]+" | sort | uniq | wc -l)
dbcount=$(psql ${dbname} -c "select count(distinct(experiments)) from analysesexperiments" -t -A)
if [ ! "$dbcount" -eq "$filecount" ]; then
    echo "WARNING: $dbcount Analysis experiment refs in database, but $filecount in input file!"
    all_counts_correct=0
else
    echo "Analysis experiment ref count correct ($dbcount Experiments)"
fi

echo
echo "Checking Experiments..."

# Get dataset id for experiments to help simplify queries
dataset_name="SRA Experiment Metadata data set"
dataset_id=$(psql ${dbname} -c "select id from dataset where dataset.name='${dataset_name}'" -t -A)

if [ -z $dataset_id ]; then
    echo "ERROR: Experiment data set not found in database"
    dataset_id=0
fi

# Check number of experiments in database
# Each line in file is unique experiment so count number of lines (minus header)
filecount=$(tail -n +2 /db/*/datasets/experiment/experiment.txt | wc -l)
dbcount=$(psql ${dbname} -c "select count(e.id) from experiment e join datasetsexperiment de on de.experiment=e.id where de.datasets=${dataset_id}" -t -A)
if [ ! "$dbcount" -eq "$filecount" ]; then
    echo "WARNING: $dbcount Experiments in database, but $filecount in input file!"
    all_counts_correct=0
else
    echo "Experiment count correct ($dbcount Experiments)"
fi

# Check that unique identifier is really unique
check_unique_field "Experiment" "experimentid"

# Check that organism ref was set
check_null_field "Experiment" "organismid" "organism ref"

echo
echo "SUMMARY:"
if [ $all_counts_correct -eq 0 ]; then
    echo "Some counts were incorrect!"
else
    echo "All counts were correct."
fi
echo

#!/bin/bash  

########################################################
# remove_dupes_from_db.sh
#
# Test to actually remove items from db rather than
# just clear out columns. 
########################################################

# variables and functions common to all test scripts
variablesfile="../../common/script_vars_faangmine1.2.sh"
functionsfile="../../common/intermine_v1_functions.sh"


# files/vars for this script
inputdir="$PWD/input_files"
rundatetime=`date +%Y%m%d%H%M`
logdir="$PWD/log/log_remove_dupes_from_db_${rundatetime}"
outfile="${logdir}/script_run.out"
geneclass="org.intermine.model.bio.Gene"

# Source variables file
. $variablesfile

# Source functions file
. $functionsfile


# Create log directory if it doesn't already exist
if [ ! -d "${logdir}" ]; then
    mkdir -p ${logdir}
fi

echo "Script output will be stored in file $outfile"
echo

startdate=`date`
echo "Beginning date and time: ${startdate}" > $outfile
echo >> $outfile

# Check if input directory exists
if [ ! -d "${inputdir}" ]; then
    echo "ERROR: Input directory ${inputdir} does not exist." >> $outfile
    exit 1
fi

# Initialize input file
inputfile="${inputdir}/gene_ids_to_remove_from_db.txt"
touch ${inputfile}

# Get the organismID for bos taurus (needed for part 3)
bovineorgid=$(psql -U ${dbuser} -d faangmine -c "SELECT id FROM organism WHERE shortname='B. taurus'" -t -A 2>>$outfile)
# Remove newline character
bovineorgid=$(tr -d '\n' <<< ${bovineorgid})
echo "Bos taurus organism ID is: ${bovineorgid}" >> $outfile
echo >> $outfile

#----------------------------
# UPDATE #1: PUBMED GENE LIST
#----------------------------

echo "Generating list of pubmed genes to alter in database" >> $outfile
genewhere="WHERE primaryidentifier NOT LIKE 'E%' AND primaryidentifier!='X54156.1' AND source='Ensembl'"
sfwhere="${genewhere} AND class='${geneclass}'"
# Note the ">" use here to clear out anything that might be in the input file from a previous run
psql -U ${dbuser} -d faangmine -c "SELECT id FROM gene ${genewhere}" -t -A > ${inputfile}
echo "Running query: SELECT id FROM gene ${genewhere}" >> $outfile

# Check counts, exit if they don't match
genecount=$(psql -U ${dbuser} -d faangmine -c "SELECT count(*) FROM gene ${genewhere}" -t -A 2>>$outfile)
featurecount=$(psql -U ${dbuser} -d faangmine -c "SELECT count(*) FROM sequencefeature ${sfwhere}" -t -A 2>>$outfile)
if [ "$genecount" != "$featurecount" ]; then
    echo "ERROR: gene count and feature count do not match!!" >> $outfile
    echo "Gene count: ${genecount}" >> $outfile
    echo "Feature count: ${featurecount}" >> $outfile
    exit 1
fi

echo "Found ${genecount} genes" >> $outfile

#---------------------
# UPDATE #2: 'P' GENES
#---------------------

echo "Generating list of 'P' genes to alter in database" >> $outfile

genewhere="WHERE primaryidentifier LIKE '%P%' AND source='Ensembl'"
sfwhere="${genewhere} AND class='${geneclass}'"
psql -U ${dbuser} -d faangmine -c "SELECT id FROM gene ${genewhere}" -t -A >> ${inputfile}
echo "Running query: SELECT id FROM gene ${genewhere}" >> $outfile

# Check counts, exit if they don't match
genecount=$(psql -U ${dbuser} -d faangmine -c "SELECT count(*) FROM gene ${genewhere}" -t -A 2>>$outfile)
featurecount=$(psql -U ${dbuser} -d faangmine -c "SELECT count(*) FROM sequencefeature ${sfwhere}" -t -A 2>>$outfile)
if [ "$genecount" != "$featurecount" ]; then
    echo "ERROR: gene count and feature count do not match!!" >> $outfile
    echo "Gene count: ${genecount}" >> $outfile
    echo "Feature count: ${featurecount}" >> $outfile
    exit 1
fi

echo "Found ${genecount} genes" >> $outfile

#---------------------
# UPDATE #3: 'T' GENES
#---------------------

echo "Generating list of 'T' genes to alter in database" >> $outfile

genewhere="WHERE primaryidentifier LIKE '%T%' AND source='Ensembl' AND organismid!=${bovineorgid}"
sfwhere="${genewhere} AND class='${geneclass}'"

psql -U ${dbuser} -d faangmine -c "SELECT id FROM gene ${genewhere}" -t -A >> ${inputfile}
echo "Running query: SELECT id FROM gene ${genewhere}" >> $outfile

# Check counts, exit if they don't match
genecount=$(psql -U ${dbuser} -d faangmine -c "SELECT count(*) FROM gene ${genewhere}" -t -A 2>>$outfile)
featurecount=$(psql -U ${dbuser} -d faangmine -c "SELECT count(*) FROM sequencefeature ${sfwhere}" -t -A 2>>$outfile)
if [ "$genecount" != "$featurecount" ]; then
    echo "ERROR: gene count and feature count do not match!!" >> $outfile
    echo "Gene count: ${genecount}" >> $outfile
    echo "Feature count: ${featurecount}" >> $outfile
    exit 1
fi

echo "Found ${genecount} genes" >> $outfile

#-------------------------
# NOW DELETE FROM DATABASE
#-------------------------

echo "Reading gene IDs from input file ${inputfile}" >> $outfile
echo >> $outfile

# Loop through input file contents
{
    while IFS=, read geneid; do
        echo "Processing gene ID: ${geneid}" >> $outfile
        echo >> $outfile

        # Delete from gene table
        psql -U ${dbuser} -d faangmine -c "DELETE FROM gene WHERE id=${geneid}" >> $outfile

        # Delete from sequencefeature
        psql -U ${dbuser} -d faangmine -c "DELETE FROM sequencefeature WHERE id=${geneid}" >> $outfile

        # Delete from intermineobject
        psql -U ${dbuser} -d faangmine -c "DELETE FROM intermineobject WHERE id=${geneid}" >> $outfile

        # Delete from bioentity
        psql -U ${dbuser} -d faangmine -c "DELETE FROM bioentity WHERE id=${geneid}" >> $outfile

        # Delete from bioentitiesdatasets
        psql -U ${dbuser} -d faangmine -c "DELETE FROM bioentitiesdatasets WHERE bioentities=${geneid}" >> $outfile

        # Delete from bioentitiespublications
        psql -U ${dbuser} -d faangmine -c "DELETE FROM bioentitiespublications WHERE bioentities=${geneid}" >> $outfile

        echo >> $outfile
        echo "---------" >> $outfile
    done
} < ${inputfile}
echo "Database updates completed" >> $outfile

enddate=`date`
echo >> $outfile
echo "End date and time: ${enddate}" >> $outfile


#!/bin/bash  

########################################################
# quick_last_test.sh
#
# REALLY almost there now! Hopefully the last test to check
# changes made to QTL and KEGG.
#
# After loading successfully, run the post processing script.
########################################################

# variables and functions common to all intermine scripts
variablesfile="~/intermine-scripts/common/script_vars_faangmine1.2.sh"
functionsfile="$PWD/common/intermine_functions.sh"

# files/vars for this script
rundatetime=`date +%Y%m%d%H%M`
logdir="$PWD/log/loading_${rundatetime}"
outfile="${logdir}/script_run.out"

# Source variables file
. $variablesfile

# Source functions file
. $functionsfile

echo "$(timestamp) Script output will be stored in file $outfile"
echo

# Display warning prompt
#warning_prompt

# Get exit code from prompt
#ec=$?

# If exit code is 0, proceed to loading
#if [ $ec -eq 0 ]; then
    # Begin loading
 
    # Create log directory if it doesn't already exist
    if [ ! -d "${logdir}" ]; then
        mkdir ${logdir}
    fi

    startdate=`date`
    echo "$(timestamp) Beginning date and time: ${startdate}" > $outfile
    echo >> $outfile

    # Clear the existing database for a fresh load
    clean_database >> $outfile

    # Get exit code
    ec=$?

    # If exit code != 0, exit early - cannot continue loading
    if [ ! $ec -eq 0 ]; then
        echo "$(timestamp) Stopping loading due to error" >> $outfile
        exit_early >> $outfile
    fi

    # Restart postgres to clear connections
    restart_postgres >> $outfile
    
    #########################
    #                       #
    # BEGIN LOADING SOURCES #
    #                       #
    #########################

    #-----------------------------------------------------------------------------
    # Ontologies (min set)
    load_source_with_exit_on_error "evidence-ontology" >> $outfile
    load_source_with_exit_on_error "sequence-ontology" >> $outfile
    load_source_with_exit_on_error "gene-ontology" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # BioSample, BioProject, Analysis
    load_source_with_exit_on_error "faang-bioproject" >> $outfile
    load_source_with_exit_on_error "faang-biosample" >> $outfile
    load_source_with_exit_on_error "faang-analysis" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Gene info
    load_source_with_exit_on_error "human-gene-info-refseq" >> $outfile
    load_source_with_exit_on_error "mouse-gene-info-refseq" >> $outfile
    load_source_with_exit_on_error "rat-gene-info-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "human-gene-info-ensembl" >> $outfile
    load_source_with_exit_on_error "mouse-gene-info-ensembl" >> $outfile
    load_source_with_exit_on_error "rat-gene-info-ensembl" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # dbSNP - not included

    #-----------------------------------------------------------------------------
    # Genome Fasta (cat, chicken, pig)
    load_source_with_exit_on_error "Felis_catus_9.0_genome_fasta" >> $outfile
    load_source_with_exit_on_error "GRCg6a_genome_fasta" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1_genome_fasta" >> $outfile
    #restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # GFF (cat, chicken, pig) and QTL
    load_source_with_exit_on_error "Felis_catus_9.0-refseq-coding-gff" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-noncoding-gff" >> $outfile
    load_source_with_exit_on_error "GRCg6a-refseq-coding-gff" >> $outfile
    load_source_with_exit_on_error "GRCg6a-noncoding-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-refseq-coding-gff" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-noncoding-gff" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-ensembl-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "GRCg6a-ensembl-gff" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-ensembl-gff" >> $outfile
    load_source_with_exit_on_error "ARS-UCD1.2-qtl-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "GRCg6a-qtl-gff" >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-qtl-gff" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-qtl-gff" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Ensembl CDS and Protein Fasta (cat, chicken, pig)
    load_source_with_exit_on_error "Felis_catus_9.0-cds-refseq" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-protein-refseq" >> $outfile
    load_source_with_exit_on_error "GRCg6a-cds-refseq" >> $outfile
    load_source_with_exit_on_error "GRCg6a-protein-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-cds-refseq" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-protein-refseq" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-protein-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "GRCg6a-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "GRCg6a-protein-ensembl" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-protein-ensembl" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # xrefs - not included

    #-----------------------------------------------------------------------------
    # Experiment - not included

    #-----------------------------------------------------------------------------
    # Gene expression - not included

    #-----------------------------------------------------------------------------
    # Repeat region - not included

    #-----------------------------------------------------------------------------
    # Special case: first iteration uniprot
    # copy properties file over
    cp ${first_iteration_uniprot_props_file} ${uniprot_config_file}
    load_source_with_exit_on_error "uniprot-first" >> $outfile
    restart_postgres >> $outfile

    # Special case: second iteration uniprot
    # copy properties file over
    cp ${second_iteration_uniprot_props_file} ${uniprot_config_file}
    load_source_with_exit_on_error "uniprot-sec" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Misc. rest of project.xml items
    load_source_with_exit_on_error "uniprot-keywords" >> $outfile
    load_source_with_exit_on_error "uniprot-fasta" >> $outfile
    load_source_with_exit_on_error "interpro" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "protein2ipr" >> $outfile
    load_source_with_exit_on_error "reactome" >> $outfile
    load_source_with_exit_on_error "kegg" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # May need to load the next two manually! (if network issues with eutils)
    load_source_with_exit_on_error "entrez-organism" >> $outfile
    load_source_with_exit_on_error "update-publications" >> $outfile

    #########################

    # After loading all sources successfully, exit script and send email notification
    echo >> $outfile
    echo "$(timestamp) Loading completed" >> $outfile

    enddate=`date`
    echo >> $outfile
    echo "$(timestamp) End date and time: ${enddate}" >> $outfile

    send_email

#fi

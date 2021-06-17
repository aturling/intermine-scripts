#!/bin/bash  

########################################################
# continue_load_all_sources.sh
#
# Continuation of full FAANGMine load - all sources from project.xml.
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
    
    #########################
    #                       #
    # BEGIN LOADING SOURCES #
    #                       #
    #########################

    #-----------------------------------------------------------------------------
    # dbSNP - left off here
    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-V" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-VI" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-VII" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-VIII" >> $outfile
    #Empty
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-IX" >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-X" >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-XI" >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-XII" >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-XIII" >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-XIV" >> $outfile
    #load_source_with_exit_on_error "Sscrofa11.1-dbsnp-variation-XV" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Genome Fasta
    load_source_with_exit_on_error "ARS-UCD1.2_genome_fasta" >> $outfile
    load_source_with_exit_on_error "UOA_WB_1_genome_fasta" >> $outfile
    load_source_with_exit_on_error "CanFam3.1_genome_fasta" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ARS1_genome_fasta" >> $outfile
    load_source_with_exit_on_error "EquCab3.0_genome_fasta" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0_genome_fasta" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "GRCg6a_genome_fasta" >> $outfile
    load_source_with_exit_on_error "Oar_v3.1_genome_fasta" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1_genome_fasta" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # GFF (including new chipseq set)
    load_source_with_exit_on_error "chipseq" >> $outfile
    load_source_with_exit_on_error "ARS-UCD1.2-refseq-coding-gff" >> $outfile
    load_source_with_exit_on_error "ARS-UCD1.2-noncoding-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "UOA_WB_1-refseq-coding-gff" >> $outfile
    load_source_with_exit_on_error "UOA_WB_1-noncoding-gff" >> $outfile
    load_source_with_exit_on_error "CanFam3.1-refseq-coding-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-noncoding-gff" >> $outfile
    load_source_with_exit_on_error "ARS1-refseq-coding-gff" >> $outfile
    load_source_with_exit_on_error "ARS1-noncoding-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-refseq-coding-gff" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-noncoding-gff" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-refseq-coding-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-noncoding-gff" >> $outfile
    load_source_with_exit_on_error "GRCg6a-refseq-coding-gff" >> $outfile
    load_source_with_exit_on_error "GRCg6a-noncoding-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-refseq-coding-gff" >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-noncoding-gff" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-refseq-coding-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-noncoding-gff" >> $outfile
    load_source_with_exit_on_error "ARS-UCD1.2-ensembl-gff" >> $outfile
    load_source_with_exit_on_error "CanFam3.1-ensembl-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ARS1-ensembl-gff" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-ensembl-gff" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-ensembl-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "GRCg6a-ensembl-gff" >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-ensembl-gff" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-ensembl-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ARS-UCD1.2-qtl-gff" >> $outfile
    load_source_with_exit_on_error "GRCg6a-qtl-gff" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-qtl-gff" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-qtl-gff" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Ensembl CDS and Protein Fasta
    load_source_with_exit_on_error "ARS-UCD1.2-cds-refseq" >> $outfile
    load_source_with_exit_on_error "ARS-UCD1.2-protein-refseq" >> $outfile
    load_source_with_exit_on_error "UOA_WB_1-cds-refseq" >> $outfile
    load_source_with_exit_on_error "UOA_WB_1-protein-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-cds-refseq" >> $outfile
    load_source_with_exit_on_error "CanFam3.1-protein-refseq" >> $outfile
    load_source_with_exit_on_error "ARS1-cds-refseq" >> $outfile
    load_source_with_exit_on_error "ARS1-protein-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-cds-refseq" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-protein-refseq" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-cds-refseq" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-protein-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "GRCg6a-cds-refseq" >> $outfile
    load_source_with_exit_on_error "GRCg6a-protein-refseq" >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-cds-refseq" >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-protein-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-cds-refseq" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-protein-refseq" >> $outfile
    load_source_with_exit_on_error "ARS-UCD1.2-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "ARS-UCD1.2-protein-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "CanFam3.1-protein-ensembl" >> $outfile
    load_source_with_exit_on_error "ARS1-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "ARS1-protein-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-protein-ensembl" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-protein-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "GRCg6a-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "GRCg6a-protein-ensembl" >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-cds-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-protein-ensembl" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-cds-ensembl" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-protein-ensembl" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # xrefs
    load_source_with_exit_on_error "bovine-xref" >> $outfile
    load_source_with_exit_on_error "goat-xref" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "sheep-xref" >> $outfile
    load_source_with_exit_on_error "cat-xref" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "dog-xref" >> $outfile
    load_source_with_exit_on_error "horse-xref" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "chicken-xref" >> $outfile
    load_source_with_exit_on_error "pig-xref" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Experiment
    load_source_with_exit_on_error "ARS-UCD1.2-experiment" >> $outfile
    load_source_with_exit_on_error "UOA_WB_1-experiment" >> $outfile
    load_source_with_exit_on_error "CanFam3.1-experiment" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ARS1-experiment" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-experiment" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-experiment" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "GRCg6a-experiment" >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-experiment" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-experiment" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Gene expression
    load_source_with_exit_on_error "ARS-UCD1.2-rnaseq-expression-for-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ARS-UCD1.2-rnaseq-expression-for-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "UOA_WB_1-rnaseq-expression-for-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-rnaseq-expression-for-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "CanFam3.1-rnaseq-expression-for-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ARS1-rnaseq-expression-for-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ARS1-rnaseq-expression-for-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-rnaseq-expression-for-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "EquCab3.0-rnaseq-expression-for-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-rnaseq-expression-for-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-rnaseq-expression-for-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "GRCg6a-rnaseq-expression-for-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "GRCg6a-rnaseq-expression-for-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-rnaseq-expression-for-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-rnaseq-expression-for-ensembl" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-rnaseq-expression-for-refseq" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-rnaseq-expression-for-ensembl" >> $outfile
    restart_postgres >> $outfile

    #-----------------------------------------------------------------------------
    # Repeat region
    load_source_with_exit_on_error "ARS-UCD1.2-repeat-region" >> $outfile
    load_source_with_exit_on_error "UOA_WB_1-repeat-region" >> $outfile
    load_source_with_exit_on_error "CanFam3.1-repeat-region" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ARS1-repeat-region" >> $outfile
    load_source_with_exit_on_error "EquCab3.0-repeat-region" >> $outfile
    load_source_with_exit_on_error "Felis_catus_9.0-repeat-region" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "GRCg6a-repeat-region" >> $outfile
    load_source_with_exit_on_error "Oar_v3.1-repeat-region" >> $outfile
    load_source_with_exit_on_error "Sscrofa11.1-repeat-region" >> $outfile
    restart_postgres >> $outfile


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
    restart_postgres >> $outfile
    load_source_with_exit_on_error "interpro" >> $outfile
    load_source_with_exit_on_error "protein2ipr" >> $outfile
    load_source_with_exit_on_error "reactome" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ncbi-pubmed-gene" >> $outfile
    load_source_with_exit_on_error "ensembl-pubmed-gene" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "ensembl-compara" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "orthodb" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "omim" >> $outfile
    load_source_with_exit_on_error "bovine-biogrid" >> $outfile
    restart_postgres >> $outfile
    load_source_with_exit_on_error "psi-intact" >> $outfile
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

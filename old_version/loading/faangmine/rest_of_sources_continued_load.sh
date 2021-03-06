#!/bin/bash  

#########################################################
# Continue loading rest of sources - DO NOT wipe db first.
#########################################################

# variables and functions common to all intermine scripts
variablesfile="../../common/script_vars_faangmine1.2.sh"
functionsfile="../../common/intermine_v1_functions.sh"

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

# Create log directory if it doesn't already exist
if [ ! -d "${logdir}" ]; then
    mkdir ${logdir}
fi

startdate=`date`
echo "$(timestamp) Beginning date and time: ${startdate}" > $outfile
echo >> $outfile

# Restart postgres to clear connections
restart_postgres >> $outfile
    
#########################
#                       #
# BEGIN LOADING SOURCES #
#                       #
#########################

# Ontologies etc.
#load_source_with_exit_on_error "uberon" >> $outfile
#load_source_with_exit_on_error "mouse-anatomy-ontology" >> $outfile
#load_source_with_exit_on_error "brenda-tissue-ontology" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "clinical-measurement-ontology" >> $outfile
#load_source_with_exit_on_error "livestock-breed-ontology" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "livestock-product-trait-ontology" >> $outfile
#load_source_with_exit_on_error "vertebrate-trait-ontology" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "evidence-ontology" >> $outfile
#load_source_with_exit_on_error "psi-mi-ontology" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "sequence-ontology" >> $outfile
#load_source_with_exit_on_error "gene-ontology" >> $outfile
#restart_postgres >> $outfile
#
# Gene info
#load_source_with_exit_on_error "human-gene-info-refseq" >> $outfile
#load_source_with_exit_on_error "mouse-gene-info-refseq" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "rat-gene-info-refseq" >> $outfile
#load_source_with_exit_on_error "human-gene-info-ensembl" >> $outfile
#restart_postgres >> $outfile
#

#-----------------------------------------------------------------
#  ERROR #1    *    *    *
#load_source_with_exit_on_error "mouse-gene-info-ensembl" >> $outfile
#-----------------------------------------------------------------

#-----------------------------------------------------------------
#  ERROR #2    *    *    *
#load_source_with_exit_on_error "rat-gene-info-ensembl" >> $outfile
#-----------------------------------------------------------------

#restart_postgres >> $outfile
#
# FASTA
#load_source_with_exit_on_error "ARS-UCD1.2_genome_fasta" >> $outfile
#load_source_with_exit_on_error "UOA_WB_1_genome_fasta" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "CanFam3.1_genome_fasta" >> $outfile
#load_source_with_exit_on_error "ARS1_genome_fasta" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "EquCab3.0_genome_fasta" >> $outfile
#load_source_with_exit_on_error "Felis_catus_9.0_genome_fasta" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "GRCg6a_genome_fasta" >> $outfile
#load_source_with_exit_on_error "Oar_v3.1_genome_fasta" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "Sscrofa11.1_genome_fasta" >> $outfile
# chipseq
#load_source_with_exit_on_error "chipseq" >> $outfile
#restart_postgres >> $outfile
#
# RefSeq coding/noncoding
#load_source_with_exit_on_error "ARS-UCD1.2-refseq-coding-gff" >> $outfile
#load_source_with_exit_on_error "ARS-UCD1.2-noncoding-gff" >> $outfile
#load_source_with_exit_on_error "UOA_WB_1-refseq-coding-gff" >> $outfile
#load_source_with_exit_on_error "UOA_WB_1-noncoding-gff" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "CanFam3.1-refseq-coding-gff" >> $outfile
#load_source_with_exit_on_error "CanFam3.1-noncoding-gff" >> $outfile
#load_source_with_exit_on_error "ARS1-refseq-coding-gff" >> $outfile
#load_source_with_exit_on_error "ARS1-noncoding-gff" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "EquCab3.0-refseq-coding-gff" >> $outfile
#load_source_with_exit_on_error "EquCab3.0-noncoding-gff" >> $outfile
#load_source_with_exit_on_error "Felis_catus_9.0-refseq-coding-gff" >> $outfile
#load_source_with_exit_on_error "Felis_catus_9.0-noncoding-gff" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "GRCg6a-refseq-coding-gff" >> $outfile
#load_source_with_exit_on_error "GRCg6a-noncoding-gff" >> $outfile
#load_source_with_exit_on_error "Oar_v3.1-refseq-coding-gff" >> $outfile
#load_source_with_exit_on_error "Oar_v3.1-noncoding-gff" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "Sscrofa11.1-refseq-coding-gff" >> $outfile
#load_source_with_exit_on_error "Sscrofa11.1-noncoding-gff" >> $outfile
#restart_postgres >> $outfile
#
# Ensembl etc.
#load_source_with_exit_on_error "ARS-UCD1.2-ensembl-gff" >> $outfile

#-----------------------------------------------------------------
# Can't test this round - need to fix Ensembl/Ensembl95 thing
#load_source_with_exit_on_error "CanFam3.1-ensembl-gff" >> $outfile
#-----------------------------------------------------------------

#load_source_with_exit_on_error "ARS1-ensembl-gff" >> $outfile
#load_source_with_exit_on_error "EquCab3.0-ensembl-gff" >> $outfile
#restart_postgres >> $outfile

#-----------------------------------------------------------------
# same error as above
# Can't test this round - need to fix Ensembl/Ensembl95 thing
#load_source_with_exit_on_error "Felis_catus_9.0-ensembl-gff" >> $outfile
#-----------------------------------------------------------------

#load_source_with_exit_on_error "GRCg6a-ensembl-gff" >> $outfile
#load_source_with_exit_on_error "Oar_v3.1-ensembl-gff" >> $outfile

#-----------------------------------------------------------------
# same error as above
# Can't test this round - need to fix Ensembl/Ensembl95 thing
#load_source_with_exit_on_error "Sscrofa11.1-ensembl-gff" >> $outfile
#-----------------------------------------------------------------

#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "ARS-UCD1.2-qtl-gff" >> $outfile
#load_source_with_exit_on_error "GRCg6a-qtl-gff" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "Oar_v3.1-qtl-gff" >> $outfile
#load_source_with_exit_on_error "Sscrofa11.1-qtl-gff" >> $outfile
#restart_postgres >> $outfile
#
# CDS/protein
#load_source_with_exit_on_error "ARS-UCD1.2-cds-refseq" >> $outfile
#load_source_with_exit_on_error "ARS-UCD1.2-protein-refseq" >> $outfile
#load_source_with_exit_on_error "UOA_WB_1-cds-refseq" >> $outfile
#load_source_with_exit_on_error "UOA_WB_1-protein-refseq" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "CanFam3.1-cds-refseq" >> $outfile
#load_source_with_exit_on_error "CanFam3.1-protein-refseq" >> $outfile
#load_source_with_exit_on_error "ARS1-cds-refseq" >> $outfile
#load_source_with_exit_on_error "ARS1-protein-refseq" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "EquCab3.0-cds-refseq" >> $outfile
#load_source_with_exit_on_error "EquCab3.0-protein-refseq" >> $outfile
#load_source_with_exit_on_error "Felis_catus_9.0-cds-refseq" >> $outfile
#load_source_with_exit_on_error "Felis_catus_9.0-protein-refseq" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "GRCg6a-cds-refseq" >> $outfile
#load_source_with_exit_on_error "GRCg6a-protein-refseq" >> $outfile
#load_source_with_exit_on_error "Oar_v3.1-cds-refseq" >> $outfile
#load_source_with_exit_on_error "Oar_v3.1-protein-refseq" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "Sscrofa11.1-cds-refseq" >> $outfile
#load_source_with_exit_on_error "Sscrofa11.1-protein-refseq" >> $outfile
#load_source_with_exit_on_error "ARS-UCD1.2-cds-ensembl" >> $outfile
#load_source_with_exit_on_error "ARS-UCD1.2-protein-ensembl" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "CanFam3.1-cds-ensembl" >> $outfile
#load_source_with_exit_on_error "CanFam3.1-protein-ensembl" >> $outfile
#load_source_with_exit_on_error "ARS1-cds-ensembl" >> $outfile
#load_source_with_exit_on_error "ARS1-protein-ensembl" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "EquCab3.0-cds-ensembl" >> $outfile
#load_source_with_exit_on_error "EquCab3.0-protein-ensembl" >> $outfile
#load_source_with_exit_on_error "Felis_catus_9.0-cds-ensembl" >> $outfile
#load_source_with_exit_on_error "Felis_catus_9.0-protein-ensembl" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "GRCg6a-cds-ensembl" >> $outfile
#load_source_with_exit_on_error "GRCg6a-protein-ensembl" >> $outfile
#load_source_with_exit_on_error "Oar_v3.1-cds-ensembl" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "Oar_v3.1-protein-ensembl" >> $outfile
#load_source_with_exit_on_error "Sscrofa11.1-cds-ensembl" >> $outfile
#load_source_with_exit_on_error "Sscrofa11.1-protein-ensembl" >> $outfile
#restart_postgres >> $outfile
#
# xref
#load_source_with_exit_on_error "bovine-xref" >> $outfile
#load_source_with_exit_on_error "goat-xref" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "sheep-xref" >> $outfile
#load_source_with_exit_on_error "cat-xref" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "dog-xref" >> $outfile
#load_source_with_exit_on_error "horse-xref" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "chicken-xref" >> $outfile
#load_source_with_exit_on_error "pig-xref" >> $outfile
#restart_postgres >> $outfile
#
# repeat region
#load_source_with_exit_on_error "ARS-UCD1.2-repeat-region" >> $outfile
#load_source_with_exit_on_error "UOA_WB_1-repeat-region" >> $outfile
#load_source_with_exit_on_error "CanFam3.1-repeat-region" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "ARS1-repeat-region" >> $outfile
#load_source_with_exit_on_error "EquCab3.0-repeat-region" >> $outfile
#load_source_with_exit_on_error "Felis_catus_9.0-repeat-region" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "GRCg6a-repeat-region" >> $outfile
#load_source_with_exit_on_error "Oar_v3.1-repeat-region" >> $outfile
#load_source_with_exit_on_error "Sscrofa11.1-repeat-region" >> $outfile
#restart_postgres >> $outfile
#
# Special case: first iteration uniprot
# copy properties file over
#cp ${first_iteration_uniprot_props_file} ${uniprot_config_file}
#load_source_with_exit_on_error "uniprot-first" >> $outfile
#restart_postgres >> $outfile

#-----------------------------------------------------------------
# Can't fix this round - Ensembl95/Ensembl thing
# Special case: second iteration uniprot
# copy properties file over
#cp ${second_iteration_uniprot_props_file} ${uniprot_config_file}
#load_source_with_exit_on_error "uniprot-sec" >> $outfile
#restart_postgres >> $outfile
#-----------------------------------------------------------------

# misc.
#load_source_with_exit_on_error "uniprot-keywords" >> $outfile
#load_source_with_exit_on_error "uniprot-fasta" >> $outfile
#load_source_with_exit_on_error "interpro" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "protein2ipr" >> $outfile
#load_source_with_exit_on_error "reactome" >> $outfile
#load_source_with_exit_on_error "ncbi-pubmed-gene" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "ensembl-pubmed-gene" >> $outfile
#load_source_with_exit_on_error "ensembl-compara" >> $outfile
#load_source_with_exit_on_error "treefam-extended" >> $outfile
#restart_postgres >> $outfile
#
#load_source_with_exit_on_error "orthodb" >> $outfile
#load_source_with_exit_on_error "omim" >> $outfile
#load_source_with_exit_on_error "bovine-biogrid" >> $outfile
#restart_postgres >> $outfile

#load_source_with_exit_on_error "psi-intact" >> $outfile
#load_source_with_exit_on_error "kegg" >> $outfile
#restart_postgres >> $outfile

#load_source_with_exit_on_error "entrez-organism" >> $outfile
load_source_with_exit_on_error "update-publications" >> $outfile

#########################

# After loading all sources successfully, exit script and send email notification
echo >> $outfile
echo "$(timestamp) Loading completed" >> $outfile

enddate=`date`
echo >> $outfile
echo "$(timestamp) End date and time: ${enddate}" >> $outfile

send_email

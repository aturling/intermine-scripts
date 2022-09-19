#!/bin/bash

function add_mine_sources {
    # Ontologies
    add_ontologies_sources

    # SNP
    add_snp "Zm00001eb.1"

    # Genome FASTA
    add_genome_fasta

    # RefSeq gff
    add_refseq_gff

    # Maize gff
    add_maize_gff

    # CDS/Protein FASTA
    add_cds_protein_fasta "RefSeq" "Gramene/MaizeGDB"

    # xrefs
    add_xrefs

    # aliases
    add_aliases

    # Maize expression
    add_maize_expression

    #---Gene.source merge key line---
    add_merge_key_note

    # UniProt
    add_uniprot "RefSeq" "Gramene"

    # InterPro
    add_interpro

    # Add InterPro to protein (protein2ipr)
    add_protein2ipr

    # KEGG
    add_kegg

    # Reactome-Gramene
    add_reactome_gramene

    # Community gff - no Gene.source loaded
    add_community_gff

    # Ensembl Plant BioMart
    add_biomart

    # Update data sources
    add_update_data_sources

    # Update pubs and organisms (NCBI Entrez)
    add_ncbi_entrez
}

function add_mine_post_processes {
    add_post_processes
}

#!/bin/bash

function add_mine_sources {
    # Ontologies
    add_ontologies_sources

    # SNP
    add_snp "B73 Zm00001eb.1"

    # Genome FASTA
    add_genome_fasta

    # RefSeq gff
    add_refseq_gff

    # Maize gff
    add_maize_gff

    # CDS/Protein FASTA
    add_cds_protein_fasta "RefSeq" "MaizeGDB"

    # xrefs
    add_xrefs "MaizeMine"

    # aliases
    add_aliases "MaizeMine"

    # Maize expression
    add_maize_expression

    #---Gene.source merge key line---
    add_merge_key_note

    # UniProt
    add_uniprot "RefSeq" "Gramene"

    # InterPro
    add_interpro

    # InterPro to protein (protein2ipr)
    add_protein2ipr

    # GO annotation
    add_go_annotation "MaizeGDB" "MaizeGDB-PANNZER GO annotation data set"

    # KEGG
    add_kegg

    # Reactome-Gramene
    add_reactome_gramene

    # MaizeGDB-E2P2-Pathway
    add_e2p2_pathway

    # Community gff - no Gene.source loaded
    add_community_gff

    # MaizeGDB-PanGene
    add_pangene

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

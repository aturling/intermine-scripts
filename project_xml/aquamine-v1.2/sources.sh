#!/bin/bash

function add_mine_sources {
    # Ontologies
    add_ontologies_sources

    # SNP
    add_snp "Ensembl"

    # Genome FASTA
    add_genome_fasta

    # RefSeq gff
    add_refseq_gff

    # Ensembl gff
    add_ensembl_gff

    # CDS/Protein FASTA
    add_cds_protein_fasta "RefSeq" "Ensembl"

    # xrefs
    add_xrefs "AquaMine"

    # Gene expression
    add_gene_expression

    # Experiment metadata
    add_aquamine_experiment

    # PubMed
    add_pubmed "RefSeq" "Ensembl"

    #---Gene.source merge key line---
    add_merge_key_note

    # UniProt
    add_uniprot "RefSeq" "Ensembl"

    # InterPro
    add_interpro

    # Add InterPro to protein (protein2ipr)
    add_protein2ipr

    # KEGG
    add_kegg

    # Reactome
    # Manually specify organisms by taxon id list (depends on mine)
    add_reactome "6454 6565 6596 6687 6689 6706 6728 7227 7227 7918 7950 7955 7955 7994 7998 8010 8017 8018 8019 8022 8023 8030 8049 8128 8167 8245 8267 9606 9606 27706 29159 34816 41447 48193 59861 74940 195615 225164 417921 481459 1841481 2691554"

    # RBHs
    add_rbh "AquaMine" "AquaMine reciprocal best hits data set"

    # GO-Annotation
    add_go_annotation "UniProt" "UniProt GO annotation data set" "true"
    add_go_annotation "Ensembl" "Ensembl GO annotation data set" "true"
    add_go_annotation "AquaMine" "AquaMine GO annotation data set" "false"

    # OrthoDB
    add_orthodb

    # AquaMine-ortho
    add_aquamine_ortho

    # EnsemblCompara
    add_ensembl_compara

    # Update data sources
    add_update_data_sources

    # Update pubs and organisms (NCBI Entrez)
    add_ncbi_entrez
}

function add_mine_post_processes {
    add_default_post_processes
}

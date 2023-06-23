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
    add_reactome "7227 7955 9606"

    # RBHs
    add_rbh "AquaMine" "AquaMine reciprocal best hits data set"

    # GO-Annotation
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

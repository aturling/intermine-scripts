#!/bin/bash

function add_mine_sources {
    # Ontologies
    add_ontologies_sources

    # Genome FASTA
    add_genome_fasta

    # RefSeq gff
    add_refseq_gff

    # Ensembl gff
    add_ensembl_gff

    # OGS gff
    add_ogs_gff

    # Genbank gff
    add_genbank_gff

    # CDS/Protein FASTA
    add_cds_protein_fasta "RefSeq" "Ensembl" "OGS" "Genbank"

    # xrefs
    add_xrefs "HGD"

    # aliases
    add_aliases "HGD"

    # PubMed
    add_pubmed "RefSeq"

    #---Gene.source merge key line---
    add_merge_key_note

    # UniProt
    # No longer need iteration for OGS
    add_uniprot "RefSeq" "FlyBase"

    # InterPro
    add_interpro

    # Add InterPro to protein (protein2ipr)
    add_protein2ipr

    # KEGG
    add_kegg

    # Reactome
    # Manually specify organisms by taxon id list (depends on mine)
    add_reactome "7227"

    # RBHs
    add_rbh

    # OrthoDB
    add_orthodb

    # HGD-ortho
    add_hgd_ortho

    # GO-Annotation
    add_go_annotation "HGD"
    add_go_annotation "FlyBase"
    add_go_annotation "UniProt"

    # Add BioGRID
    add_biogrid

    # Add IntAct
    add_intact "7227"

    # Update data sources
    add_update_data_sources

    # Update pubs and organisms (NCBI Entrez)
    add_ncbi_entrez
}

function add_mine_post_processes {
    add_default_post_processes
}

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
    # For v1.7 instead use this function below:
    #add_gene_xrefs "HGD"

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
    # Note: in v1.7 add data source and data set title as params
    add_rbh "HGD"

    # GO-Annotation
    add_go_annotation "HGD" "HGD GO annotation data set" "false"
    add_go_annotation "FlyBase" "FlyBase GO annotation data set" "true"
    add_go_annotation "UniProt" "UniProt GO annotation data set" "true"

    # Add BioGRID
    add_biogrid

    # Add IntAct
    add_intact "7227"

    # OrthoDB
    add_orthodb

    # HGD-ortho
    add_hgd_ortho

    # Update data sources
    add_update_data_sources

    # Update pubs and organisms (NCBI Entrez)
    add_ncbi_entrez
}

function add_mine_post_processes {
    add_default_post_processes
}

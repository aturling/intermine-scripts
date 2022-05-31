#!/bin/bash

function add_mine_sources {
    # Ontologies
    add_ontologies_sources

    # SNP (TODO)
    add_snp

    # BioProject, BioSample, and Analysis data
    add_bioproject_data

    # Genome FASTA
    add_genome_fasta

    # RefSeq gff
    add_refseq_gff

    # Ensembl gff
    add_ensembl_gff

    # Custom gene info
    add_custom_gene_info "RefSeq" "Ensembl"

    # CDS/Protein FASTA
    add_cds_protein_fasta "RefSeq" "Ensembl"

    # xrefs
    add_xrefs

    # KEGG
    add_kegg

    # PubMed (TODO)
    add_pubmed

    #---Gene.source merge key line---
    add_merge_key_note

    # UniProt
    add_uniprot "RefSeq" "Ensembl"

    # Add QTL GFF (TODO)
    add_qtl_gff

    # InterPro
    add_interpro

    # Add InterPro to protein (protein2ipr)
    add_protein2ipr

    # Reactome (TODO)
    add_reactome

    # OrthoDB (TODO)
    add_orthodb

    # EnsemblCompara (TODO)
    add_ensembl_compara

    # OMIM (TODO)
    add_omim

    # Update pubs and organisms (NCBI Entrez)
    add_ncbi_entrez
}

function add_mine_post_processes {
    # Add SNP versions of post processes (TODO)
    # add_post_processes_snp

    # Using no SNP versions temporarily
    add_post_processes_no_snp
}

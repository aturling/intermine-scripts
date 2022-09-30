#!/bin/bash

function add_mine_sources {
    # Ontologies
    add_ontologies_sources

    # SNP
    add_snp "Ensembl"

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
    add_reactome "9031 9606 9615 9823 9913 10090 10116"

    # OrthoDB
    add_orthodb

    # EnsemblCompara
    add_ensembl_compara

    # OMIM
    add_omim

    # Add FAANG GFF
    add_faang_gff

    # Add QTL GFF
    add_qtl_gff

    # Add BioGRID
    add_biogrid

    # Add IntAct
    add_intact "9606 9796 9823 9913 9925 9940 10090 10116"

    # Update data sources
    add_update_data_sources

    # Update pubs and organisms (NCBI Entrez)
    add_ncbi_entrez
}

function add_mine_post_processes {
    add_post_processes
}

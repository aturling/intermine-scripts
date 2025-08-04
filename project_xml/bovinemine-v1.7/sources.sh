#!/bin/bash

function add_mine_sources {
    # Ontologies
    add_ontologies_sources

    # SNP
    add_snp

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
    add_gene_xrefs "BovineMine"

    # Gene expression
    add_bovine_gene_expression

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
    # For BovineMine: B. taurus only
    add_reactome "9913"

    # OrthoDB
    add_orthodb

    # EnsemblCompara
    add_ensembl_compara

    # Add QTL GFF
    add_qtl_gff

    # Add candidate region GFF
    add_candidate_region_gff

    # Expression metadata
    add_bovine_expression_metadata

    # Add GplusE
    # Not including in BovineMine 1.7
    #add_gpluse

    # GO-Annotation 
    add_go_annotation "Ensembl" "Ensembl Biomart GO annotation data set" "true"
    add_go_annotation "NCBI" "NCBI GO annotation data set" "true"

    # Add BioGRID
    # Not including in BovineMine 1.7
    #add_biogrid

    # Add IntAct
    # Not including in BovineMine 1.7
    #add_intact "9606 9913 10090 10116"

    # Update data sources
    add_update_data_sources

    # Update pubs and organisms (NCBI Entrez)
    add_ncbi_entrez
}

function add_mine_post_processes {
    add_default_post_processes
}

#!/bin/bash

function add_mine_sources {
    # Ontologies
    # Data source directories: datasets/ontologies/<ontology_abbr>/<ontology>.obo (symlink to *.obo
    # file with release version)
    add_ontologies_sources

    # SNP
    # Data source directories: datasets/SNP/<organism>/<assembly>/part_<roman_numeral>
    # Usage: add_snp "<Gene.source>", e.g.,:
    add_snp "Ensembl"

    # BioProject, BioSample, and Analysis data (FAANGMine only)
    # Data source directories: datasets/FAANG-bioproject, datasets/FAANG-biosample, datasets/FAANG-analysis
    add_bioproject_data

    # Genome FASTA
    # Data source directories: genome/<organism>/<assembly>
    add_genome_fasta

    # RefSeq gff
    # Data source directories: datasets/RefSeq/annotations/<organism>/<assembly>
    add_refseq_gff

    # Ensembl gff
    # Data source directories: datasets/Ensembl/annotations/<organism>/<assembly>
    add_ensembl_gff

    # Maize gff (MaizeMine only)
    # Data source directories: datasets/MaizeGDB/annotations/<organism>/<assembly>
    add_maize_gff

    # Custom gene info
    # Data source directories: datasets/custom-gene-info/<source>/<organism>
    # Usage: add_custom_gene_info "<DataSource.name>" list, e.g.,
    add_custom_gene_info "RefSeq" "Ensembl"

    # CDS/Protein FASTA
    # Data source directories: datasets/<source>/cds_fasta/<organism>/<assembly>,
    #                          datasets/<source>/protein_fasta/<organism>/<assembly>
    # Usage: add_cds_protein_fasta "<DataSource.name>" list, e.g.,
    add_cds_protein_fasta "RefSeq" "Ensembl"

    # xrefs
    # Data source directories: datasets/xref/<organism>
    add_xrefs

    # aliases
    # Data source directories: datasets/alias/<organism>
    add_aliases

    # Maize expression (MaizeMine only)
    # Data source directories: datasets/expression, datasets/expression/metadata
    add_maize_expression

    # PubMed
    # Data source directories: datasets/ncbi-pubmed-gene, datasets/ensembl-pubmed-gene
    # Usage: add_pubmed "<DataSource.name>" list, e.g.,
    add_pubmed "RefSeq" "Ensembl"

    #---Gene.source merge key line---
    add_merge_key_note

    # UniProt
    # Data source directory: datasets/UniProt
    # Usage: add_uniprot "<source>" list, e.g.,
    add_uniprot "RefSeq" "Ensembl"

    # InterPro
    # Data source directory: datasets/InterPro
    add_interpro

    # Add InterPro to protein (protein2ipr)
    # Data source directory: datasets/protein2ipr
    add_protein2ipr

    # KEGG
    # Data source directories: datasets/KEGG_genes, datasets/KEGG_meta (optional)
    add_kegg

    # Reactome
    # Data source directory: datasets/Reactome
    # Manually specify organisms by taxon id list (depends on mine)
    # Usage: add_reactome "<taxon id list>", e.g.,
    add_reactome "9031 9606 9615 9685 9796 9823 9913 9925 9940 10090 10116 89462"

    # Reactome-Gramene (MaizeMine only)
    # Data source directory: datasets/reactome_pathways
    add_reactome_gramene

    # Community gff (MaizeMine only) - no Gene.source loaded
    # Data source directories: datasets/community_datasets/<source>
    add_community_gff

    # Ensembl Plant BioMart (MaizeMine only)
    # Data source directory: datasets/ensembl-plant-biomart
    add_biomart

    # OrthoDB
    # Data source directory: datasets/OrthoDB
    add_orthodb

    # EnsemblCompara
    # Data source directory: datasets/EnsemblCompara
    add_ensembl_compara

    # OMIM
    # Data source directory: datasets/omim
    add_omim

    # Add FAANG GFF
    # Data source directories: datasets/FAANG-gff/<organism>/<assembly>
    add_faang_gff

    # Add QTL GFF
    # Data source directories: datasets/QTL/<organism>/<assembly>
    add_qtl_gff

    # Add BioGRID
    # Data source directory: datasets/BioGRID
    add_biogrid

    # Add IntAct
    # Data source directory: datasets/IntAct
    # Manually specify organisms by taxon id list (depends on mine)
    # Usage: add_intact "<taxon id list>", e.g.,
    add_intact "9606 9796 9823 9913 9925 9940 10090 10116"

    # Update data sources
    # Data source directories: datasets/UniProt/xrefs, datasets/datasource-info (optional)  
    add_update_data_sources

    # Update pubs and organisms (NCBI Entrez)
    add_ncbi_entrez
}

function add_mine_post_processes {
    add_post_processes
}

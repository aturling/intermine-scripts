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

    # Genbank gff
    # TODO
    #add_genbank_gff

    # OGS gff
    # TODO
    #add_ogs_gff

    # CDS/Protein FASTA
    # TODO
    #add_cds_protein_fasta "RefSeq" "Ensembl" "OGS" "Genbank"
    add_cds_protein_fasta "RefSeq" "Ensembl"

    # xrefs
    add_xrefs

    # aliases
    add_aliases

    # PubMed
    # TODO - not sure which source(s)
    #add_pubmed "RefSeq" "Ensembl"

    #---Gene.source merge key line---
    add_merge_key_note

    # UniProt
    # TODO
    #add_uniprot "RefSeq" "Ensembl" "OGS"
    add_uniprot "RefSeq" "Ensembl"

    # InterPro
    add_interpro

    # Add InterPro to protein (protein2ipr)
    add_protein2ipr

    # KEGG
    add_kegg
    # TODO - kegg metadata

    # Reactome
    # Manually specify organisms by taxon id list (depends on mine)
    add_reactome "7227"

    # OrthoDB
    add_orthodb

    # HGD-ortho
    # TODO

    # GO-Annotation
    # TODO
    #add_go_annotation

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
    add_post_processes
}

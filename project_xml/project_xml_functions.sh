#!/bin/bash  

# Get mine name and version

function get_mine_name {
    grep "db.production.datasource.databaseName" ~/.intermine/*.properties | tail -n 1 | awk -F'=' '{print $2}'
}

# Get /db/<mine_dir> directory name
function get_mine_dir {
    find /db -mindepth 1 -maxdepth 1 -type d -name "*mine*"
}

# Get bio/sources version
function get_bio_source_version {
    grep "systemProp.imVersion" /db/*/intermine/bio/gradle.properties | awk -F'=' '{print $2}'
}

# Get abbreviation from directory name (organism name)
function get_abbr {
    dir=$1

    genus=$(echo $dir | cut -d_ -f1)
    species=$(echo $dir | rev | cut -d_ -f1 | rev)
    abbr="${genus:0:1}${species:0:3}"

    echo "$abbr"
}

# Add project.xml headers
function add_headers {
    echo "Initializing project.xml file"

    echo '<?xml version="1.0" encoding="utf-8"?>' >> $outfile
    echo '<project type="bio">' >> $outfile
    echo '  <property name="target.model" value="genomic"/>' >> $outfile
    echo '  <property name="common.os.prefix" value="common"/>' >> $outfile
  
    # Get properties name
    prop_file=$(find ~/.intermine/ -type f -name "*.properties" -printf "%f\n")
    echo "Properties file is: $prop_file"
    echo "  <property name=\"intermine.properties.file\" value=\"${prop_file}\"/>" >> $outfile

    echo '  <property name="default.intermine.properties.file" location="../default.intermine.integrate.properties"/>' >> $outfile
    echo >> $outfile
}

function add_footers {
    echo "Finalizing project.xml file"

    echo "</project>" >> $outfile
}

function add_ontologies_sources {
    echo "Adding ontologies"

    echo "    <!--Ontologies-->" >> $outfile
    
    license="https://creativecommons.org/licenses/by/4.0/"

    # First SO.obo
    echo "    <source name=\"so\" type=\"so\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.file\" location=\"so.obo\"/>" >> $outfile
    echo "      <property name=\"licence\" value=\"${license}\"/>" >> $outfile
    echo "    </source>" >> $outfile

    # Next GO.obo
    # Check that it exists first
    go_file=$(find ${mine_dir}/datasets/ontologies/GO -maxdepth 1 -type f -name "*.obo" -printf "%f\n")
    if [ ! -z $go_file ]; then
        echo "    <source name=\"go\" type=\"go\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.file\" location=\"${mine_dir}/datasets/ontologies/GO/${go_file}\"/>" >> $outfile
        echo "      <property name=\"createrelations\" value=\"true\"/>" >> $outfile
        echo "      <property name="licence" value="${license}"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi

    # Next ECO.obo
    # Check that it exists first
    eco_file=$(find ${mine_dir}/datasets/ontologies/ECO -maxdepth 1 -type f -name "*.obo" -printf "%f\n")
    if [ ! -z $eco_file ]; then
        echo "    <source name=\"evidence-ontology\" type=\"go\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.file\" location=\"${mine_dir}/datasets/ontologies/ECO/${eco_file}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi

    # Rest of ontologies: iterate over all datasets/ontologies dirs
    dirs=$(find ${mine_dir}/datasets/ontologies -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
    for dir in $dirs; do
        make_source=0
        ontology_name=""
        if [ $dir == "SO" ]; then
            true
        elif [ $dir == "GO" ]; then
            true
        elif [ $dir == "ECO" ]; then
            true
        elif [ $dir == "BTO" ]; then
            ontology_name="brenda-tissue-ontology"
            make_source=1
        elif [ $dir == "CMO" ]; then
            ontology_name="clinical-measurement-ontology"
            make_source=1
        elif [ $dir == "LBO" ]; then
            ontology_name="livestock-breed-ontology"
            make_source=1
        elif [ $dir == "LPTO" ]; then
            ontology_name="livestock-product-trait-ontology"
            make_source=1
        elif [ $dir == "MAO" ]; then
            ontology_name="mouse-anatomy-ontology"
            make_source=1
        elif [ $dir == "PMO" ]; then
            ontology_name="psi-mi-ontology"
            make_source=1
        elif [ $dir == "UAO" ]; then
            ontology_name="uber-anatomy-ontology"
            make_source=1
        elif [ $dir == "VTO" ]; then
            ontology_name="vertebrate-trait-ontology"
            make_source=1
        elif [ $dir == "PO" ]; then
            ontology_name="plant-ontology"
            make_source=1
        elif [ $dir == "HAO" ]; then
            ontology_name="hymenoptera-anatomy-ontology"
            make_source=1
        else
            echo "WARNING: UNRECOGNIZED ONTOLOGY: ${dir}"
        fi

        # Make source if applicable
        if [ "$make_source" -eq "1" ]; then
            # Check that it exists first
            obo_file=$(find ${mine_dir}/datasets/ontologies/${dir} -maxdepth 1 -type f -name "*.obo" -printf "%f\n")
            if [ ! -z $obo_file ]; then
                echo "    <source name=\"${ontology_name}\" type=\"${ontology_name}\" version=\"${source_version}\">" >> $outfile
                echo "      <property name=\"src.data.file\" location=\"${mine_dir}/datasets/ontologies/${dir}/${obo_file}\"/>" >> $outfile
                echo "    </source>" >> $outfile
            fi
        fi
    done

    echo >> $outfile
    echo >> $outfile
}

function add_snp {
    echo "Adding SNP"

    echo "    <!--SNP-->" >> $outfile

    # parts given with roman numerals, max 20
    declare -a parts=("part_I" "part_II" "part_III" "part_IV" "part_V" "part_VI" "part_VII" "part_VIII" "part_IX" "part_X"
                      "part_XI" "part_XII" "part_XIII" "part_XIV" "part_XV" "part_XVI" "part_XVII" "part_XVIII" "part_XIX" "part_XX")
    numparts=${#parts[@]}

    # Iterate over organisms
    orgs=$(find ${mine_dir}/datasets/SNP -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
    for org in $orgs; do
        abbr=$(get_abbr "$org")
        fullname=$(echo "$org" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        data_source=$(grep -i "$fullname" snp_sources.tab | cut -f2)
        # Iterate over assemblies (usually just one)
        assemblies=$(find ${mine_dir}/datasets/SNP/${org} -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
        for assembly in $assemblies; do
            # Get number of parts
            actual_numparts=$(ls ${mine_dir}/datasets/SNP/${org}/${assembly} | wc -l)
            if [ "$actual_numparts" -ge "$numparts" ]; then
                echo
                echo "WARNING: More than 20 SNP parts found! Organism: $org, assembly: $assembly"
                echo
            fi
            # Iterate over parts
            for (( i=0; i<${actual_numparts}; i++ )); do
                this_part=${parts[i]}
                # Check that there are .vcf files first
                files=$(ls ${mine_dir}/datasets/SNP/${org}/${assembly}/${this_part} 2>/dev/null)
                if [ ! -z "$files" ]; then
                    echo "    <source name=\"${abbr}-snp-variation-${this_part}\" type=\"snp-variation\" version=\"${source_version}\">" >> $outfile
                    echo "      <property name=\"snp-variation.dataSetTitle\" value=\"Variants and Variant Effects from ${data_source}\"/>" >> $outfile
                    echo "      <property name=\"snp-variation.dataSourceName\" value=\"${data_source}\"/>" >> $outfile
                    echo "      <property name=\"snp-variation.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
                    echo "      <property name=\"snp-variation.assemblyVersion\" value=\"${assembly}\"/>" >> $outfile
                    echo "      <property name=\"snp-variation.geneSource\" value=\"Ensembl\"/>" >> $outfile
                    echo "      <property name=\"snp-variation.includes\" value=\"*.vcf\"/>" >> $outfile
                    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/SNP/${org}/${assembly}/${this_part}\"/>" >> $outfile
                    echo "    </source>" >> $outfile
                fi
            done
        done
    done

    echo >> $outfile
    echo >> $outfile
}

function add_bioproject_data {
    echo "Adding bioproject/biosample/analysis sources"

    echo "    <!--BioProject, BioSample, and Analysis metadata-->" >> $outfile
    echo "    <source name=\"faang-bioproject\" type=\"faang-bioproject\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/FAANG-bioproject\"/>" >> $outfile
    echo "    </source>" >> $outfile
    echo "    <source name=\"faang-biosample\" type=\"faang-biosample\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/FAANG-biosample\"/>" >> $outfile
    echo "    </source>" >> $outfile
    echo "    <source name=\"faang-analysis\" type=\"faang-analysis\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/FAANG-analysis\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_genome_fasta {
    echo "Adding genome FASTA"

    echo "    <!--Genome Fasta-->" >> $outfile

    source_type="fasta-assembly"

    # Iterate over species dirs
    
    dirs=$(find ${mine_dir}/datasets/genome -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
    for dir in $dirs; do
        fullname=$(echo "$dir" | sed 's/_/ /'g)
        genus=$(echo $dir | cut -d_ -f1)
        species=$(echo $dir | rev | cut -d_ -f1 | rev)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$dir")
        data_source=$(find ${mine_dir}/datasets/genome/${dir}/ -type f -name "*.fa" -printf "%f\n" | grep -oE ".+_genom" | sed 's/_genom//')
        assembly=$(find ${mine_dir}/datasets/genome/${dir}/ -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

        echo "    <source name=\"${abbr}-fasta\" type=\"${source_type}\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"${source_type}.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"${source_type}.dataSourceName\" value=\"${fullname^} Genome ${data_source}\"/>" >> $outfile
        echo "      <property name=\"${source_type}.dataSetTitle\" value=\"${fullname^} Genome ${assembly}\"/>" >> $outfile
        echo "      <property name=\"${source_type}.className\" value=\"org.intermine.model.bio.Chromosome\"/>" >> $outfile
        echo "      <property name=\"${source_type}.sequenceType\" value=\"dna\"/>" >> $outfile
        echo "      <property name=\"${source_type}.includes\" value=\"*.fa\"/>" >> $outfile
        echo "      <property name=\"${source_type}.assemblyVersion\" value=\"${assembly}\"/>" >> $outfile
        echo "      <property name=\"${source_type}.loaderClassName\" value=\"org.intermine.bio.dataconversion.FastaAssemblyLoaderTask\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/genome/${dir}/${assembly}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    done

    echo >> $outfile
    echo >> $outfile
}

function add_refseq_gff {
    echo "Adding RefSeq GFF"

    echo "    <!--RefSeq GFF-->" >> $outfile

    # Iterate over species dirs
    dirs=$(find ${mine_dir}/datasets/RefSeq/annotations -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
    for dir in $dirs; do
        fullname=$(echo "$dir" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$dir")
        assembly=$(find ${mine_dir}/datasets/RefSeq/annotations/${dir} -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

        # RefSeq-genes
        echo "    <source name=\"${abbr}-refseq-gff\" type=\"refseq-gff\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSourceName\" value=\"RefSeq\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSetTitle\" value=\"NCBI RefSeq gene set for ${assembly}\"/>" >> $outfile
        echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile 
        echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/RefSeq/annotations/${dir}/${assembly}/genes\"/>" >> $outfile
        echo "    </source>" >> $outfile      

        # RefSeq-pseudogenes-transcribed
        echo "    <source name=\"${abbr}-pseudogene-refseq-gff\" type=\"pseudogene-refseq-gff\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSourceName\" value=\"RefSeq\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSetTitle\" value=\"NCBI RefSeq pseudogene (transcribed) set for ${assembly}\"/>" >> $outfile
        echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
        echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/RefSeq/annotations/${dir}/${assembly}/pseudogenes_transcribed\"/>" >> $outfile
        echo "    </source>" >> $outfile

        # RefSeq-pseudogenes-not-transcribed
        echo "    <source name=\"${abbr}-pseudogene-refseq-nottranscribed-gff\" type=\"pseudogene-refseq-nottranscribed-gff\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSourceName\" value=\"RefSeq\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSetTitle\" value=\"NCBI RefSeq pseudogene (not transcribed) set for ${assembly}\"/>" >> $outfile
        echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
        echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/RefSeq/annotations/${dir}/${assembly}/pseudogenes_nottranscribed\"/>" >> $outfile
        echo "    </source>" >> $outfile
    done

    echo >> $outfile
    echo >> $outfile
}

function add_ensembl_gff {
    echo "Adding Ensembl GFF"

    echo "    <!--Ensembl GFF-->" >> $outfile

    # Iterate over species dirs
    dirs=$(find ${mine_dir}/datasets/Ensembl/annotations -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
    for dir in $dirs; do
        fullname=$(echo "$dir" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$dir")
        assembly=$(find ${mine_dir}/datasets/Ensembl/annotations/${dir} -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

        # Ensembl-genes
        echo "    <source name=\"${abbr}-ensembl-gff\" type=\"ensembl-gff\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSourceName\" value=\"Ensembl\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSetTitle\" value=\"Ensembl gene set for ${assembly}\"/>" >> $outfile
        echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
        echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/Ensembl/annotations/${dir}/${assembly}/genes\"/>" >> $outfile
        echo "    </source>" >> $outfile 

        # Ensembl-pseudogenes
        echo "    <source name=\"${abbr}-pseudogene-ensembl-gff\" type=\"pseudogene-ensembl-gff\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSourceName\" value=\"Ensembl\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSetTitle\" value=\"Ensembl pseudogene set for ${assembly}\"/>" >> $outfile
        echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
        echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/Ensembl/annotations/${dir}/${assembly}/pseudogenes\"/>" >> $outfile
        echo "    </source>" >> $outfile
    done

    echo >> $outfile
    echo >> $outfile
}

function add_custom_gene_info_source {
    source=$1
    source_dataset="$source"
    if [ "$source" == "RefSeq" ]; then
        source_dataset="NCBI RefSeq"
    fi

    echo "    <!--${source}-->" >> $outfile

    # Iterate over species
    dirs=$(find ${mine_dir}/datasets/custom-gene-info/$source -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
    for dir in $dirs; do
        fullname=$(echo "$dir" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$dir")

        echo "    <source name=\"${abbr}-gene-info-${source,,}\" type=\"custom-gene-info\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"dataSourceName\" value=\"${source}\"/>" >> $outfile
        echo "      <property name=\"dataSetTitle\" value=\"${source_dataset} genes for ${fullname^}\"/>" >> $outfile
        echo "      <property name=\"geneSource\" value=\"${source}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/custom-gene-info/${source}/${dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    done

    echo >> $outfile
}

function add_custom_gene_info {
    echo "Adding custom gene info"

    echo "    <!--Custom Gene Info (reference species)-->" >> $outfile
    echo "    <!--Load directly after other GFF-->" >> $outfile
    echo >> $outfile

    for source_name in "$@"; do
        add_custom_gene_info_source $source_name
    done

    echo >> $outfile
}

function add_cds_protein_fasta_source {
    source=$1
    source_type="fasta-assembly"

    echo "    <!--${source} CDS and Protein Fasta-->" >> $outfile

    # Iterate over species dirs
    dirs=$(find ${mine_dir}/datasets/${source}/annotations -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
    for dir in $dirs; do
        fullname=$(echo "$dir" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$dir")
        assembly=$(find ${mine_dir}/datasets/${source}/annotations/${dir} -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

        # CDS
        echo "    <source name=\"${abbr}-${source,,}-cds\" type=\"${source_type}\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"${source_type}.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"${source_type}.dataSourceName\" value=\"${source}\"/>" >> $outfile
        echo "      <property name=\"${source_type}.dataSetTitle\" value=\"${fullname^} ${source} Coding Sequence\"/>" >> $outfile 
        echo "      <property name=\"${source_type}.className\" value=\"org.intermine.model.bio.CodingSequence\"/>" >> $outfile
        echo "      <property name=\"${source_type}.classAttribute\" value=\"primaryIdentifier\"/>" >> $outfile
        echo "      <property name=\"${source_type}.geneSource\" value=\"${source}\"/>" >> $outfile
        echo "      <property name=\"${source_type}.sequenceType\" value=\"dna\"/>" >> $outfile
        echo "      <property name=\"${source_type}.includes\" value=\"*.fa\"/>" >> $outfile
        echo "      <property name=\"${source_type}.idSuffix\" value=\"-CDS\"/>" >> $outfile
        echo "      <property name=\"${source_type}.loaderClassName\" value=\"org.intermine.bio.dataconversion.CDSFastaAssemblyLoaderTask\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${source}/cds_fasta/${dir}/${assembly}\"/>" >> $outfile
        echo "    </source>" >> $outfile

        # Protein
        echo "    <source name=\"${abbr}-${source,,}-protein\" type=\"${source_type}\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"${source_type}.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"${source_type}.dataSourceName\" value=\"${source}\"/>" >> $outfile
        echo "      <property name=\"${source_type}.dataSetTitle\" value=\"${fullname^} ${source} Protein Sequence\"/>" >> $outfile
        echo "      <property name=\"${source_type}.className\" value=\"org.intermine.model.bio.Polypeptide\"/>" >> $outfile
        echo "      <property name=\"${source_type}.classAttribute\" value=\"primaryIdentifier\"/>" >> $outfile
        echo "      <property name=\"${source_type}.geneSource\" value=\"${source}\"/>" >> $outfile
        echo "      <property name=\"${source_type}.sequenceType\" value=\"protein\"/>" >> $outfile
        echo "      <property name=\"${source_type}.includes\" value=\"*.fa\"/>" >> $outfile
        echo "      <property name=\"${source_type}.loaderClassName\" value=\"org.intermine.bio.dataconversion.ProteinFastaAssemblyLoaderTask\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${source}/protein_fasta/${dir}/${assembly}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    done

    echo >> $outfile
    echo >> $outfile
}

function add_cds_protein_fasta {
    echo "Adding CDS/protein FASTA"

    for source_name in "$@"; do
        add_cds_protein_fasta_source $source_name
    done
}

function add_xrefs {
    echo "Adding xrefs"

    echo "    <!--xRefs-->" >> $outfile

    # Iterate over species dirs
    dirs=$(find ${mine_dir}/datasets/xref -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
    for dir in $dirs; do
        fullname=$(echo "$dir" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$dir")

        echo "    <source name=\"${abbr}-xref\" type=\"cross-references\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/xref/${dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    done

    echo >> $outfile
    echo >> $outfile
}

function add_kegg {
    echo "Adding KEGG"

    echo "    <!--KEGG-->" >> $outfile

    taxon_id_list=$(cut -f1 ${mine_dir}/datasets/KEGG_genes/map_title.tab | sort -n | uniq | xargs)

    echo "    <source name=\"kegg\" type=\"kegg-pathway\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"pathway.organisms\" value=\"${taxon_id_list}\"/>" >> $outfile
    echo "      <property name=\"urlPrefix\" value=\"https://www.genome.jp/pathway/\"/>" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/KEGG_genes\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_pubmed_source {
    source=$1

    pubmed_dir="ncbi-pubmed-gene"
    if [ "$source" == "Ensembl" ]; then
        pubmed_dir="ensembl-pubmed-gene"
    fi

    pubmed_file=$(find ${mine_dir}/datasets/${pubmed_dir} -mindepth 1 -maxdepth 1 -type f)
    if [ ! -z $pubmed_file ]; then
        taxon_ids=$(cut -f1 ${pubmed_file} | sort -n | uniq | xargs)

        echo "    <source name=\"${pubmed_dir,,}\" type=\"pubmed-gene\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"geneSource\" value=\"${source}\"/>" >> $outfile
        echo "      <property name=\"pubmed.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${pubmed_dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    else
        echo "Warning: no pubmed gene data file in ${pubmed_dir}"
    fi
}

function add_pubmed {
    echo "Adding PubMed"

    echo "    <!--PubMed-->" >> $outfile

    for source_name in "$@"; do
        add_pubmed_source $source_name
    done

    echo >> $outfile
    echo >> $outfile
}

function add_merge_key_note {
    echo "    <!--Beyond this point, Gene.source is not used as a merge key for genes-->" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function get_uniprot_dir_name {
    # Folder name could be UniProt or uniprot
    find ${mine_dir}/datasets -mindepth 1 -maxdepth 1 -type d -name "*ni*rot" -printf "%f\n"
}

function get_uniprot_taxon_id_list {
    dirname=$1
    find ${mine_dir}/datasets/${dirname} -type f -name "*uniprot*.xml" -printf "%f\n" | grep -Eo '[0-9]*' | sort -n | uniq | xargs
}

function add_uniprot_source {
    source=$1
    index=$2
    cardinal="First"
    if [ "$index" -eq "2" ]; then
        cardinal="Second"
    elif [ "$index" -eq "3" ]; then
        cardinal="Third"
    fi
    dirname=$(get_uniprot_dir_name)
    taxon_id_list=$(get_uniprot_taxon_id_list "$dirname")

    echo "    <!--${cardinal} iteration UniProt: ${source}-->" >> $outfile

    echo "    <source name=\"uniprot-to-${source,,}\" type=\"uniprot\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"uniprot.organisms\" value=\"${taxon_id_list}\"/>" >> $outfile
    echo "      <property name=\"creatego\" value=\"true\"/>" >> $outfile
    echo "      <property name=\"creategenes\" value=\"true\"/>" >> $outfile
    echo "      <property name=\"allowduplicates\" value=\"false\"/>" >> $outfile
    echo "      <property name=\"loadfragments\" value=\"true\"/>" >> $outfile
    echo "      <property name=\"loadtrembl\" value=\"true\"/>" >> $outfile
    echo "      <property name=\"configFile\" value=\"uniprot-to-${source,,}_config.properties\"/>" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${dirname}\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
}

function add_uniprot_fasta {
    echo "    <!--UniProt-Fasta-->" >> $outfile

    dirname=$(get_uniprot_dir_name)
    taxon_id_list=$(get_uniprot_taxon_id_list "$dirname")

    echo "    <source name=\"uniprot-fasta\" type=\"fasta\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"fasta.taxonId\" value=\"${taxon_id_list}\"/>" >> $outfile
    echo "      <property name=\"fasta.className\" value=\"org.intermine.model.bio.Protein\"/>" >> $outfile
    echo "      <property name=\"fasta.classAttribute\" value=\"primaryAccession\"/>" >> $outfile
    echo "      <property name=\"fasta.dataSourceName\" value=\"UniProt\"/>" >> $outfile
    echo "      <property name=\"fasta.dataSetTitle\" value=\"UniProt Fasta\"/>" >> $outfile
    echo "      <property name=\"fasta.includes\" value=\"uniprot_sprot_varsplic.fasta\"/>" >> $outfile
    echo "      <property name=\"fasta.sequenceType\" value=\"protein\"/>" >> $outfile
    echo "      <property name=\"fasta.loaderClassName\" value=\"org.intermine.bio.dataconversion.UniProtFastaLoaderTask\"/>" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${dirname}\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
}

function add_uniprot_keywords {
    echo "    <!--UniProt-keywords-->" >> $outfile

    dirname=$(get_uniprot_dir_name)
    taxon_id_list=$(get_uniprot_taxon_id_list "$dirname")

    echo "    <source name=\"uniprot-keywords\" type=\"uniprot-keywords\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${dirname}\"/>" >> $outfile
    echo "      <property name=\"src.data.dir.includes\" value=\"keywlist.xml\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_uniprot {
    echo "Adding UniProt"

    echo "    <!--UniProt-->" >> $outfile
    echo >> $outfile

    index=1
    for source_name in "$@"; do
        add_uniprot_source "$source_name" "$index"
        index=$((index+1))
    done

    # UniProt FASTA
    add_uniprot_fasta

    # UniProt keywords
    add_uniprot_keywords
}

function add_qtl_gff {
    echo "Adding QTL GFF"

    echo "    <!--QTL GFF-->" >> $outfile
    echo "    <!--No Gene.source so load these here (not with rest of GFFs)-->" >> $outfile

    # Iterate over species dirs
    dirs=$(find ${mine_dir}/datasets/QTL -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
    for dir in $dirs; do
        fullname=$(echo "$dir" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$dir")
        assembly=$(find ${mine_dir}/datasets/QTL/${dir} -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

        echo "    <source name=\"${abbr}-qtl-gff\" type=\"qtl-gff\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSourceName\" value=\"Animal QTLdb\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSetTitle\" value=\"${fullname^} QTL from Animal QTLdb data set\"/>" >> $outfile
        echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
        echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/QTL/${dir}/${assembly}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    done

    echo >> $outfile
    echo >> $outfile
}

function get_interpro_dir_name {
    # Folder name could be InterPro or interpro
    find ${mine_dir}/datasets -mindepth 1 -maxdepth 1 -type d -name "*nter*ro" -printf "%f\n"
}

function add_interpro {
    echo "Adding InterPro"

    echo "    <!--InterPro-->" >> $outfile

    dirname=$(get_interpro_dir_name)

    echo "    <source name=\"interpro\" type=\"interpro\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${dirname}\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_protein2ipr {
    echo "Adding InterPro to protein (protein2ipr)"

    echo "    <!--InterPro to protein (protein2ipr)-->" >> $outfile

    echo "    <source name=\"protein2ipr\" type=\"protein2ipr\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/protein2ipr\"/>" >> $outfile
    echo "      <property name=\"includes\" value=\"protein2ipr.dat\"/>" >> $outfile
    echo "      <property name=\"osAlias\" value=\"os.production\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_reactome {
    echo "Adding Reactome"

    echo "    <!--Reactome-->" >> $outfile

    taxon_ids="$1"
    echo "    <source name=\"reactome\" type=\"reactome\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/Reactome\"/>" >> $outfile
    echo "      <property name=\"reactome.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_biogrid {
    echo "Adding BioGRID"

    echo "    <!--BioGRID-->" >> $outfile

    taxon_label="NCBITax:"
    taxon_ids=$(grep -rsoE "${taxon_label}\s+[0-9]+" ${mine_dir}/datasets/BioGRID/ | awk -F"${taxon_label}" '{print $2}' | sort -n | xargs)

    echo "    <source name=\"biogrid\" type=\"biogrid\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/BioGRID\"/>" >> $outfile
    echo "      <property name=\"src.data.dir.includes\" value=\"*.xml\"/>" >> $outfile
    echo "      <property name=\"biogrid.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_orthodb {
    echo "Adding OrthoDB"

    taxon_ids=$(awk -F'\t' '{print $6}' ${mine_dir}/datasets/OrthoDB/*.tab  | sort -n | uniq | xargs)

    echo "    <!--OrthoDB-->" >> $outfile
    echo "    <!--Data file(s) must be sorted on column 2 before loading!-->" >> $outfile

    echo "    <source name=\"orthodb\" type=\"orthodb-clusters\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"dataSourceName\" value=\"OrthoDB\"/>" >> $outfile
    echo "      <property name=\"dataSetTitle\" value=\"OrthoDB data set\"/>" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/OrthoDB\"/>" >> $outfile
    echo "      <property name=\"orthodb.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_ensembl_compara {
    echo "Adding EnsemblCompara"

    echo "    <!--EnsemblCompara-->" >> $outfile

    # Get taxon ID list
    taxon_ids=$(find ${mine_dir}/datasets/EnsemblCompara/ -type f -printf '%f\n' | awk -F'_' '{printf "%s\\n\n%s\\n\n", $1, $2}' | sed 's/\\n//g' | sort -n | uniq | xargs)

    echo "    <source name=\"ensembl-compara\" type=\"ensembl-compara\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"ensemblcompara.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
    echo "      <property name=\"ensemblcompara.homologues\" value=\"${taxon_ids}\"/>" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/EnsemblCompara\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_omim {
    echo "Adding OMIM"

    echo "    <!--OMIM-->" >> $outfile

    echo "    <source name=\"omim\" type=\"omim\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/omim\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_update_data_sources {
    echo "Adding Update Data Sources"

    echo "    <!--Load these last sources at the end, after all other sources-->" >> $outfile

    echo >> $outfile
    echo >> $outfile

    echo "    <!--Update data sources-->" >> $outfile

    echo "    <source name=\"update-data-sources\" type=\"update-data-sources\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.file\" location=\"datasources.xml\"/>" >> $outfile
    echo "      <property name=\"dataSourceFile\" value=\"${mine_dir}/datasets/UniProt/xrefs/dbxref.txt\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo "    <!--Custom data source info not in UniProt file-->" >> $outfile
    echo "    <source name=\"update-data-sources-custom\" type=\"update-data-sources\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.file\" location=\"datasources-custom.xml\"/>" >> $outfile
    echo "      <property name=\"dataSourceFile\" value=\"${mine_dir}/datasets/datasource-info/customsources.txt\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_ncbi_entrez {
    echo "Adding NCBI Entrez"

    echo "    <!--NCBI Entrez-->" >> $outfile

    echo "    <source name=\"update-publications\" type=\"update-publications\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.file\" location=\"publications.xml\"/>" >> $outfile
    echo "      <property name=\"loadFullRecord\" value=\"true\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo "    <source name=\"entrez-organism\" type=\"entrez-organism\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.file\" location=\"organisms.xml\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
}

function add_post_processes_no_snp {
    echo "    <post-process name=\"create-chromosome-locations-and-lengths\"/>" >> $outfile
    echo "    <post-process name=\"create-references\"/>" >> $outfile
    echo "    <post-process name=\"transfer-sequences\"/>" >> $outfile
    echo "    <post-process name=\"create-overlap-view\"/>" >> $outfile
    echo "    <post-process name=\"create-location-overlap-index\"/>" >> $outfile
    echo "    <post-process name=\"do-sources\"/>" >> $outfile
    echo "    <post-process name=\"create-attribute-indexes\"/>" >> $outfile
    echo "    <post-process name=\"create-search-index\"/>" >> $outfile
    echo "    <post-process name=\"summarise-objectstore\"/>" >> $outfile
    echo "    <post-process name=\"create-autocomplete-index\"/>" >> $outfile

    echo >> $outfile
}

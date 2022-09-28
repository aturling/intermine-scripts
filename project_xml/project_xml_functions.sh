#!/bin/bash  

# Get mine name and version

function get_mine_name {
    local num_files=$(find ~/.intermine/*.properties 2>/dev/null | wc -l)
    if [ "$num_files" -eq 1 ]; then
        grep "db.production.datasource.databaseName" ~/.intermine/*.properties | tail -n 1 | awk -F'=' '{print $2}'
    elif [ "$num_files" -gt 1 ]; then
        echo "ERROR: More than one .properties file exists in ~/.intermine/ directory." 1>&2
        exit 1
    else
        echo "ERROR: InterMine properties file not found in ~/.intermine/ directory." 1>&2
        exit 1
    fi
}

# Get /db/<mine_dir> directory name
function get_mine_dir {
    local num_dirs=$(find /db -mindepth 1 -maxdepth 1 -type d -name "*mine*" 2>/dev/null | wc -l)
    if [ "$num_dirs" -ne 1 ]; then
        echo "ERROR: Can't find mine dir as subdirectory of /db" 1>&2
        exit 1
    else
        find /db -mindepth 1 -maxdepth 1 -type d -name "*mine*"
    fi
}

# Get bio/sources version
function get_bio_source_version {
    local gradle_file="${mine_dir}/intermine/bio/gradle.properties"
    local source_version=$(grep "systemProp.imVersion" $gradle_file 2>/dev/null | awk -F'=' '{print $2}')
    if [ -z "$source_version" ]; then
        echo "ERROR: Cannot get source version from $gradle_file" 1>&2
        exit 1
    else
        echo "$source_version"
    fi
}

# Get org names in a subdirectory
function get_orgs {
    local data_subdir=$1

    local data_dir=${mine_dir}/datasets/${data_subdir}
    local num_orgs=$(find ${data_dir} -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    if [ $num_orgs -eq 0 ]; then
        echo "WARNING: $data_subdir does not exist or is empty" 1>&2
        return 1
    fi
    find ${data_dir} -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort
}

# Get assemblies in org subdirectory
function get_assemblies {
    # Functionally equivalent to getting organism names
    get_orgs "$1"
}

# Get abbreviation from directory name (organism name)
function get_abbr {
    local dir=$1

    local genus=$(echo $dir | cut -d_ -f1)
    local species=$(echo $dir | rev | cut -d_ -f1 | rev)
    local abbr="${genus:0:1}${species:0:3}"

    echo "$abbr"
}

function get_append_assembly {
    num_assemblies=$2
    assembly=$1

    # Append assembly if multiple assemblies, or if mine has non-unique
    # abbreviations
    # (So far just HymenopteraMine)
    mine_basename=$(grep "webapp.path"  ~/.intermine/*.properties | tail -n 1 | awk -F'=' '{print $2}')
    append_assembly=""
    if [[ $num_assemblies -gt 1 ]] || [[ "$mine_basename" == "hymenopteramine" ]]; then
        append_assembly="-$assembly"
    fi 

    echo "$append_assembly"
}

# Whether to include assembly with abbreviation
# (Some mines have non-unique abbreviations)
function include_assembly {
    mine_basename=$(grep "webapp.path"  ~/.intermine/*.properties | tail -n 1 | awk -F'=' '{print $2}')
    if [ "$mine_basename" == "hymenopteramine" ]; then
        return true
    fi
    return false  
}

# Verify that directory exists; print warning if it does not
# and do not add source to project.xml
function check_dir {
    local dirname=$1
    if [ ! -d "$dirname" ]; then
        echo "WARNING: Directory $dirname does not exist" 1>&2
        return 1
    fi
    return 0
}

# Verify that file exists; print warning if it does not
# and do not add source to project.xml
function check_file {
    local filename=$1
    if [ ! -f "$filename" ]; then
        echo "WARNING: $filename does not exist" 1>&2
        return 1
    fi
    return 0
}

# Add project.xml headers
function add_headers {
    echo
    echo "* Initializing project.xml file"

    echo '<?xml version="1.0" encoding="utf-8"?>' >> $outfile
    echo '<project type="bio">' >> $outfile
    echo '  <property name="target.model" value="genomic"/>' >> $outfile
    echo '  <property name="common.os.prefix" value="common"/>' >> $outfile
  
    # Get properties name
    prop_file=$(find ~/.intermine/ -type f -name "*.properties" -printf "%f\n")
    echo "  <property name=\"intermine.properties.file\" value=\"${prop_file}\"/>" >> $outfile

    echo '  <property name="default.intermine.properties.file" location="../default.intermine.integrate.properties"/>' >> $outfile
    echo >> $outfile
}

function add_footers {
    echo "* Finalizing project.xml file"

    echo "</project>" >> $outfile
}

function add_ontologies_sources {
    echo "+ Adding ontologies"

    echo "    <!--Ontologies-->" >> $outfile
    
    license="https://creativecommons.org/licenses/by/4.0/"

    # First SO.obo
    echo "  + Adding ontology: sequence-ontology"
    echo "    <source name=\"so\" type=\"so\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.file\" location=\"so.obo\"/>" >> $outfile
    echo "      <property name=\"licence\" value=\"${license}\"/>" >> $outfile
    echo "    </source>" >> $outfile

    # Next GO.obo
    # Check that it exists first
    go_file=$(find ${mine_dir}/datasets/ontologies/GO -maxdepth 1 -type f -name "*.obo" -printf "%f\n")
    if [ ! -z $go_file ]; then
        echo "  + Adding ontology: gene-ontology"
        echo "    <source name=\"go\" type=\"go\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.file\" location=\"${mine_dir}/datasets/ontologies/GO/${go_file}\"/>" >> $outfile
        echo "      <property name=\"createrelations\" value=\"true\"/>" >> $outfile
        echo "      <property name=\"licence\" value=\"${license}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    else
        echo "WARNING: go.obo not found" 1>&2
    fi

    # Rest of ontologies: iterate over all datasets/ontologies dirs
    dirs=$(find ${mine_dir}/datasets/ontologies -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
    for dir in $dirs; do
        make_source=0
        ontology_name=""
        if [ $dir == "SO" ]; then
            true
        elif [ $dir == "GO" ]; then
            true
        elif [ $dir == "ATOL" ]; then
            ontology_name="animal-trait-ontology-for-livestock"
            make_source=1
        elif [ $dir == "BTO" ]; then
            ontology_name="brenda-tissue-ontology"
            make_source=1
        elif [ $dir == "CL" ]; then
            ontology_name="cell-ontology"
            make_source=1
        elif [ $dir == "CMO" ]; then
            ontology_name="clinical-measurement-ontology"
            make_source=1
        elif [ $dir == "ECO" ]; then
            ontology_name="evidence-ontology"
            make_source=1
        elif [ $dir == "EFO" ]; then
            ontology_name="experimental-factor-ontology"
            make_source=1
        elif [ $dir == "EOL" ]; then
            ontology_name="environment-ontology-for-livestock"
            make_source=1
        elif [ $dir == "HP" ]; then
            ontology_name="human-phenotype-ontology"
            make_source=1
        elif [ $dir == "HsapDv" ]; then
            ontology_name="human-developmental-stage-ontology"
            make_source=1
        elif [ $dir == "LBO" ]; then
            ontology_name="livestock-breed-ontology"
            make_source=1
        elif [ $dir == "LPT" ]; then
            ontology_name="livestock-product-trait-ontology"
            make_source=1
        elif [ $dir == "MA" ]; then
            ontology_name="mouse-adult-gross-anatomy-ontology"
            make_source=1
        elif [ $dir == "MONDO" ]; then
            ontology_name="mondo-disease-ontology"
            make_source=1
        elif [ $dir == "OBI" ]; then
            ontology_name="ontology-for-biomedical-investigations"
            make_source=1
        elif [ $dir == "Orphanet" ]; then
            ontology_name="orphanet-rare-disease-ontology"
            make_source=1
        elif [ $dir == "PATO" ]; then
            ontology_name="phenotype-and-trait-ontology"
            make_source=1
        elif [ $dir == "PSI-MI" ]; then
            ontology_name="psi-mi-ontology"
            make_source=1
        elif [ $dir == "UBERON" ]; then
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
            obo_file=$(find ${mine_dir}/datasets/ontologies/${dir} -maxdepth 1 -type l -name "*.obo" -printf "%f\n")
            if [ ! -z $obo_file ]; then
                echo "  + Adding ontology: ${ontology_name}"
                echo "    <source name=\"${ontology_name}\" type=\"${ontology_name}\" version=\"${source_version}\">" >> $outfile
                echo "      <property name=\"src.data.file\" location=\"${mine_dir}/datasets/ontologies/${dir}/${obo_file}\"/>" >> $outfile
                echo "    </source>" >> $outfile
            else
                echo "WARNING: ${mine_dir}/datasets/ontologies/${dir} exists but is empty" 1>&2
            fi
        fi
    done

    echo >> $outfile
    echo >> $outfile
}

function add_snp {
    genesource=$1

    echo "+ Adding SNP"

    echo "    <!--SNP-->" >> $outfile

    # parts given with roman numerals, max 20
    declare -a parts=("part_I" "part_II" "part_III" "part_IV" "part_V" "part_VI" "part_VII" "part_VIII" "part_IX" "part_X"
                      "part_XI" "part_XII" "part_XIII" "part_XIV" "part_XV" "part_XVI" "part_XVII" "part_XVIII" "part_XIX" "part_XX")
    numparts=${#parts[@]}

    # Iterate over organisms
    data_subdir="SNP"
    orgs=$(get_orgs "$data_subdir")
    for org in $orgs; do
        abbr=$(get_abbr "$org")
        fullname=$(echo "$org" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        data_source=$(grep -i "$fullname" snp_sources.tab | cut -f2)
        # Iterate over assemblies (usually just one)
        assemblies=$(get_assemblies "${data_subdir}/${org}")
        num_assemblies=$(echo "$assemblies" | wc -l)
        for assembly in $assemblies; do
            # If multiple assemblies, append assembly version to source name
	    append_assembly=$(get_append_assembly "$assembly" "$num_assemblies")
            # Get number of parts
            actual_numparts=$(ls ${mine_dir}/datasets/${data_subdir}/${org}/${assembly} | wc -l)
            if [ "$actual_numparts" -ge "$numparts" ]; then
                echo "WARNING: More than 20 SNP parts found in ${mine_dir}/datasets/${data_subdir}/${org}/${assembly}" 1>&2
            elif [ "$actual_numparts" -eq 0 ]; then
                echo "WARNING: No SNP parts found in ${mine_dir}/datasets/${data_subdir}/${org}/${assembly}" 1>&2
            fi
            # Iterate over parts
            for (( i=0; i<${actual_numparts}; i++ )); do
                this_part=${parts[i]}
                # Check that there are .vcf files first
                files=$(ls ${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/${this_part} 2>/dev/null)
                if [ ! -z "$files" ]; then
                    echo "    <source name=\"${abbr}${append_assembly}-snp-variation-${this_part}\" type=\"snp-variation\" version=\"${source_version}\">" >> $outfile
                    echo "      <property name=\"snp-variation.dataSetTitle\" value=\"Variants and Variant Effects from ${data_source}\"/>" >> $outfile
                    echo "      <property name=\"snp-variation.dataSourceName\" value=\"${data_source}\"/>" >> $outfile
                    echo "      <property name=\"snp-variation.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
                    echo "      <property name=\"snp-variation.assemblyVersion\" value=\"${assembly}\"/>" >> $outfile
                    echo "      <property name=\"snp-variation.geneSource\" value=\"${genesource}\"/>" >> $outfile
                    echo "      <property name=\"snp-variation.includes\" value=\"*.vcf\"/>" >> $outfile
                    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/${this_part}\"/>" >> $outfile
                    echo "    </source>" >> $outfile
                #else
                #    echo "WARNING: No .vcf files found in ${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/${this_part}" 1>&2
                fi
            done
        done
    done

    echo >> $outfile
    echo >> $outfile
}

function add_faang_bioproject {
    bioproject_dir="${mine_dir}/datasets/FAANG-bioproject"
    check_dir "$bioproject_dir"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        echo "    <source name=\"faang-bioproject\" type=\"faang-bioproject\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${bioproject_dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi
}

function add_faang_biosample {
    biosample_dir="${mine_dir}/datasets/FAANG-biosample"
    check_dir "$biosample_dir"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        echo "    <source name=\"faang-biosample\" type=\"faang-biosample\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${biosample_dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi
}

function add_faang_analysis {
    analysis_dir="${mine_dir}/datasets/FAANG-analysis"
    check_dir "$analysis_dir"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        echo "    <source name=\"faang-analysis\" type=\"faang-analysis\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${analysis_dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi
}

function add_faang_experiment {
    experiment_dir="${mine_dir}/datasets/experiment"
    check_dir "$experiment_dir"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        echo "    <source name=\"faang-experiment\" type=\"faang-experiment\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${experiment_dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi
}

function add_bioproject_data {
    echo "+ Adding bioproject/biosample/analysis sources"

    echo "    <!--BioProject, BioSample, and Analysis metadata-->" >> $outfile
 
    add_faang_bioproject
    add_faang_biosample
    add_faang_analysis
    add_faang_experiment

    echo >> $outfile
    echo >> $outfile
}

function add_maize_expression {
    echo "+ Adding Maize expression"

    echo "    <!--Expression-->" >> $outfile

    expression_dir="${mine_dir}/datasets/expression"
    check_dir "$expression_dir"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        echo "    <source name=\"expression-metadata\" type=\"maize-expression-metadata\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"taxonId\" value=\"4577\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${expression_dir}/metadata\"/>" >> $outfile
        echo "      <property name=\"src.data.dir.includes\" value=\".tab\"/>" >> $outfile
        echo "    </source>" >> $outfile
        echo "    <source name=\"expression-gene\" type=\"maize-expression-gene\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"taxonId\" value=\"4577\"/>" >> $outfile
        echo "      <property name=\"entityType\" value=\"Sample\"/>" >> $outfile
        echo "      <property name=\"type\" value=\"mean\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${expression_dir}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir.includes\" value=\".tab\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi
    echo >> $outfile
    echo >> $outfile
}

function add_genome_fasta {
    echo "+ Adding genome FASTA"

    echo "    <!--Genome Fasta-->" >> $outfile

    source_type="fasta-assembly"

    # Iterate over organisms
    data_subdir="genome"
    orgs=$(get_orgs "$data_subdir")
    for org in $orgs; do
        fullname=$(echo "$org" | sed 's/_/ /'g)
        genus=$(echo $org | cut -d_ -f1)
        species=$(echo $org | rev | cut -d_ -f1 | rev)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$org")
        data_source=$(find ${mine_dir}/datasets/${data_subdir}/${org}/ -type f -name "*.fa" -printf "%f\n" | grep -oE ".+_genom" | sed 's/_genom//')
        # Iterate over assemblies (usually just one)
        assemblies=$(get_assemblies "${data_subdir}/${org}")
        num_assemblies=$(echo "$assemblies" | wc -l)
        for assembly in $assemblies; do
            # If multiple assemblies, append assembly version to source name
            append_assembly=$(get_append_assembly "$assembly" "$num_assemblies")
            echo "    <source name=\"${abbr}${append_assembly}-fasta\" type=\"${source_type}\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"${source_type}.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
            echo "      <property name=\"${source_type}.dataSourceName\" value=\"${fullname^} Genome ${data_source}\"/>" >> $outfile
            echo "      <property name=\"${source_type}.dataSetTitle\" value=\"${fullname^} Genome ${assembly}\"/>" >> $outfile
            echo "      <property name=\"${source_type}.className\" value=\"org.intermine.model.bio.Chromosome\"/>" >> $outfile
            echo "      <property name=\"${source_type}.sequenceType\" value=\"dna\"/>" >> $outfile
            echo "      <property name=\"${source_type}.includes\" value=\"*.fa\"/>" >> $outfile
            echo "      <property name=\"${source_type}.assemblyVersion\" value=\"${assembly}\"/>" >> $outfile
            echo "      <property name=\"${source_type}.loaderClassName\" value=\"org.intermine.bio.dataconversion.FastaAssemblyLoaderTask\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}/${assembly}\"/>" >> $outfile
            echo "    </source>" >> $outfile
        done
    done

    echo >> $outfile
    echo >> $outfile
}

function add_ogs_gff {
    echo "+ Adding OGS GFF"

    echo "    <!--OGS GFF-->" >> $outfile

# TODO

}

function add_maize_gff {
    echo "+ Adding Maize GFF"

    echo "    <!--Maize GFF-->" >> $outfile

    # Iterate over organisms
    data_subdir="MaizeGDB/annotations"
    orgs=$(get_orgs "$data_subdir")
    for org in $orgs; do
        fullname=$(echo "$org" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$org")
        assemblies=$(get_assemblies "${data_subdir}/${org}")
        num_assemblies=$(echo "$assemblies" | wc -l)
        for assembly in $assemblies; do
            # If multiple assemblies, append assembly version to source name
            append_assembly=$(get_append_assembly "$assembly" "$num_assemblies")
            echo "    <source name=\"${abbr}${append_assembly}-maize-gff\" type=\"maize-gff\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
            echo "      <property name=\"gff3.dataSourceName\" value=\"Gramene/MaizeGDB\"/>" >> $outfile
            echo "      <property name=\"gff3.dataSetTitle\" value=\"Zm00001eb.1 gene set for ${assembly}\"/>" >> $outfile
            echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
            echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}/${assembly}\"/>" >> $outfile
            echo "    </source>" >> $outfile
        done
    done

    echo >> $outfile
    echo >> $outfile
}

function add_community_gff_source {
    data_subdir=$1
    datasource=$2
    datasettitle=$3
    echo "  + Adding community data set: $datasettitle"

    dataset_dir="${mine_dir}/datasets/${data_subdir}"
    check_dir "$dataset_dir"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        source_abbr=$(echo "${datasource}" | tr " " "-" | tr "_" "-")

        echo "    <source name=\"${source_abbr,,}-gff\" type=\"gff\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"gff3.taxonId\" value=\"4577\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSourceName\" value=\"${datasource}\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSetTitle\" value=\"${datasettitle}\"/>" >> $outfile
        echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
        echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"Zm-B73-REFERENCE-NAM-5.0\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${dataset_dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi
}

function add_community_qtl_source {
    data_subdir=$1
    datasource=$2
    datasettitle=$3
    echo "  + Adding community data set: $datasettitle"

    dataset_dir="${mine_dir}/datasets/${data_subdir}"
    check_dir "$dataset_dir"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        source_abbr=$(echo "${datasource}" | tr " " "-" | tr "_" "-")

        echo "    <!--QTL GFF-->" >> $outfile
        echo "    <source name=\"${source_abbr,,}-qtl-gff\" type=\"qtl-gff\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"gff3.taxonId\" value=\"4577\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSourceName\" value=\"${datasource}\"/>" >> $outfile
        echo "      <property name=\"gff3.dataSetTitle\" value=\"${datasettitle}\"/>" >> $outfile
        echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
        echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"Zm-B73-REFERENCE-NAM-5.0\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${dataset_dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi
}

function add_community_gff {
    echo "+ Adding Maize Community GFF"

    echo "    <!--Community GFF-->" >> $outfile
    echo "    <!--No Gene.source so load these here (not with rest of GFFs)-->" >> $outfile

    data_dir="community_datasets"

    add_community_gff_source "$data_dir/Vollbrecht" "Vollbrecht" "Vollbrecht AcDs insertions data set"
    add_community_gff_source "$data_dir/MaizeGDB_UniformMu" "MaizeGDB_UniformMu" "MaizeGDB UniformMu insertions data set"
    add_community_gff_source "$data_dir/Grotewold_root" "Grotewold CAGE Tag Count Root" "Grotewold root transcription start sites data set"
    add_community_gff_source "$data_dir/Grotewold_shoot" "Grotewold CAGE Tag Count Shoot" "Grotewold shoot transcription start sites data set"
    add_community_gff_source "$data_dir/Stam_Enhancers/Husk" "Stam 2017 Husk H3K9ac Enhancer" "Stam 2017 Husk H3K9ac Enhancers data set"
    add_community_gff_source "$data_dir/Stam_Enhancers/Seedling" "Stam 2017 Seedling H3K9ac Enhancer" "Stam 2017 Seedling H3K9ac Enhancers data set"
    add_community_qtl_source "$data_dir/GWAS_Atlas" "GWAS Atlas" "Curated GWAS Atlas data set"
    add_community_qtl_source "$data_dir/Wallace_2014_GWAS" "Wallace 2014 GWAS" "Wallace GWAS data set"

    echo >> $outfile
    echo >> $outfile
}

function add_refseq_gff {
    echo "+ Adding RefSeq GFF"

    echo "    <!--RefSeq GFF-->" >> $outfile

    # Iterate over organisms
    data_subdir="RefSeq/annotations"
    orgs=$(get_orgs "$data_subdir")
    for org in $orgs; do
        fullname=$(echo "$org" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
	if [ -z "$taxon_id" ]; then
	    echo "WARNING: Taxon id for $fullname not found in taxon_ids.tab"
	fi
        abbr=$(get_abbr "$org")
        assemblies=$(get_assemblies "${data_subdir}/${org}")
        num_assemblies=$(echo "$assemblies" | wc -l)
        for assembly in $assemblies; do
            # If multiple assemblies, append assembly version to source name
            append_assembly=$(get_append_assembly "$assembly" "$num_assemblies")

            # RefSeq-genes
            # Check that directory not empty:
            num_gff_files=$(find "${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/genes" -mindepth 1 -maxdepth 1 -type f -name "*.gff3" 2>/dev/null | wc -l)
            if [ "$num_gff_files" -ne 0 ]; then
                echo "    <source name=\"${abbr}${append_assembly}-refseq-gff\" type=\"refseq-gff\" version=\"${source_version}\">" >> $outfile
                echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
                echo "      <property name=\"gff3.dataSourceName\" value=\"RefSeq\"/>" >> $outfile
                echo "      <property name=\"gff3.dataSetTitle\" value=\"NCBI RefSeq gene set for ${assembly}\"/>" >> $outfile
                echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile 
                echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
                echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/genes\"/>" >> $outfile
                echo "    </source>" >> $outfile
            else
                echo "WARNING: ${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/genes is empty" 
            fi

            # RefSeq-pseudogenes-transcribed
            # Check that directory not empty:
            num_gff_files=$(find "${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/pseudogenes_transcribed" -mindepth 1 -maxdepth 1 -type f -name "*.gff3" 2>/dev/null | wc -l)
            if [ "$num_gff_files" -ne 0 ]; then
                echo "    <source name=\"${abbr}${append_assembly}-pseudogene-refseq-gff\" type=\"pseudogene-refseq-gff\" version=\"${source_version}\">" >> $outfile
                echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
                echo "      <property name=\"gff3.dataSourceName\" value=\"RefSeq\"/>" >> $outfile
                echo "      <property name=\"gff3.dataSetTitle\" value=\"NCBI RefSeq pseudogene (transcribed) set for ${assembly}\"/>" >> $outfile
                echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
                echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
                echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/pseudogenes_transcribed\"/>" >> $outfile
                echo "    </source>" >> $outfile
            else
                echo "WARNING: ${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/pseudogenes_transcribed is empty"
            fi

            # RefSeq-pseudogenes-not-transcribed
            # Check that directory not empty:
            num_gff_files=$(find "${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/pseudogenes_nottranscribed" -mindepth 1 -maxdepth 1 -type f -name "*.gff3" 2>/dev/null | wc -l)
            if [ "$num_gff_files" -ne 0 ]; then
                echo "    <source name=\"${abbr}${append_assembly}-pseudogene-refseq-nottranscribed-gff\" type=\"pseudogene-refseq-nottranscribed-gff\" version=\"${source_version}\">" >> $outfile
                echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
                echo "      <property name=\"gff3.dataSourceName\" value=\"RefSeq\"/>" >> $outfile
                echo "      <property name=\"gff3.dataSetTitle\" value=\"NCBI RefSeq pseudogene (not transcribed) set for ${assembly}\"/>" >> $outfile
                echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
                echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
                echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/pseudogenes_nottranscribed\"/>" >> $outfile
                echo "    </source>" >> $outfile
            else
                echo "WARNING: ${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/pseudogenes_nottranscribed is empty"
            fi
        done
    done

    echo >> $outfile
    echo >> $outfile
}

function add_ensembl_gff {
    echo "+ Adding Ensembl GFF"

    echo "    <!--Ensembl GFF-->" >> $outfile

    # Iterate over organisms
    data_subdir="Ensembl/annotations"
    orgs=$(get_orgs "$data_subdir")
    for org in $orgs; do
        fullname=$(echo "$org" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$org")
        # Iterate over assemblies (usually just one)
        assemblies=$(get_assemblies "${data_subdir}/${org}")
        num_assemblies=$(echo "$assemblies" | wc -l)
        for assembly in $assemblies; do
            # If multiple assemblies, append assembly version to source name
            append_assembly=$(get_append_assembly "$assembly" "$num_assemblies")

            # Ensembl-genes
	    # Check that directory not empty:
	    num_gff_files=$(find "${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/genes" -mindepth 1 -maxdepth 1 -type f -name "*.gff3" 2>/dev/null | wc -l)
	    if [ "$num_gff_files" -ne 0 ]; then
                echo "    <source name=\"${abbr}${append_assembly}-ensembl-gff\" type=\"ensembl-gff\" version=\"${source_version}\">" >> $outfile
                echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
                echo "      <property name=\"gff3.dataSourceName\" value=\"Ensembl\"/>" >> $outfile
                echo "      <property name=\"gff3.dataSetTitle\" value=\"Ensembl gene set for ${assembly}\"/>" >> $outfile
                echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
                echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
                echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/genes\"/>" >> $outfile
                echo "    </source>" >> $outfile
            else
                echo "WARNING: ${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/genes is empty"
	    fi

            # Ensembl-pseudogenes
	    # Check that directory not empty:
	    num_gff_files=$(find "${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/pseudogenes" -mindepth 1 -maxdepth 1 -type f -name "*.gff3" 2>/dev/null | wc -l)
	    if [ "$num_gff_files" -ne 0 ]; then
                echo "    <source name=\"${abbr}${append_assembly}-pseudogene-ensembl-gff\" type=\"pseudogene-ensembl-gff\" version=\"${source_version}\">" >> $outfile
                echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
                echo "      <property name=\"gff3.dataSourceName\" value=\"Ensembl\"/>" >> $outfile
                echo "      <property name=\"gff3.dataSetTitle\" value=\"Ensembl pseudogene set for ${assembly}\"/>" >> $outfile
                echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
                echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
                echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/pseudogenes\"/>" >> $outfile
                echo "    </source>" >> $outfile
            else
                echo "WARNING: ${mine_dir}/datasets/${data_subdir}/${org}/${assembly}/pseudogenes is empty"
            fi
        done
    done

    echo >> $outfile
    echo >> $outfile
}

function add_custom_gene_info_source {
    source_name=$1
    source_dataset="$source_name"
    if [ "$source_name" == "RefSeq" ]; then
        source_dataset="NCBI RefSeq"
    fi

    echo "    <!--${source_name}-->" >> $outfile

    # Iterate over organisms
    data_subdir="custom-gene-info/${source_name}"
    orgs=$(get_orgs "$data_subdir")
    for org in $orgs; do
        fullname=$(echo "$org" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$org")

        echo "    <source name=\"${abbr}-gene-info-${source_name,,}\" type=\"custom-gene-info\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"dataSourceName\" value=\"${source_name}\"/>" >> $outfile
        echo "      <property name=\"dataSetTitle\" value=\"${source_dataset} genes for ${fullname^}\"/>" >> $outfile
        echo "      <property name=\"geneSource\" value=\"${source_name}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    done

    echo >> $outfile
}

function add_custom_gene_info {
    echo "+ Adding custom gene info"

    echo "    <!--Custom Gene Info (reference species)-->" >> $outfile
    echo "    <!--Load directly after other GFF-->" >> $outfile
    echo >> $outfile

    for source_name in "$@"; do
        add_custom_gene_info_source $source_name
    done

    echo >> $outfile
}

function add_cds_protein_fasta_source {
    source_name=$1
    source_type="fasta-assembly"

    echo "    <!--${source_name} CDS and Protein Fasta-->" >> $outfile

    dirname="$source_name"
    gene_source="$source_name"
    # Special case for MaizeGDB:
    if [ "$source_name" == "Gramene/MaizeGDB" ]; then
        dirname="MaizeGDB"
	gene_source="Zm00001eb.1"
    fi

    # Iterate over organisms
    # Assumes all organisms that have cds also have protein FASTA data
    data_subdir="${dirname}/cds_fasta"
    orgs=$(get_orgs "$data_subdir")
    for org in $orgs; do
        fullname=$(echo "$org" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$org")
        # Iterate over assemblies (usually just one)
        assemblies=$(get_assemblies "${data_subdir}/${org}")
        num_assemblies=$(echo "$assemblies" | wc -l)
        for assembly in $assemblies; do
            # If multiple assemblies, append assembly version to source name
            append_assembly=$(get_append_assembly "$assembly" "$num_assemblies")

            # CDS
            echo "    <source name=\"${abbr}${append_assembly}-${dirname,,}-cds\" type=\"${source_type}\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"${source_type}.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
            echo "      <property name=\"${source_type}.dataSourceName\" value=\"${source_name}\"/>" >> $outfile
            echo "      <property name=\"${source_type}.dataSetTitle\" value=\"${fullname^} ${gene_source} Coding Sequences\"/>" >> $outfile 
            echo "      <property name=\"${source_type}.className\" value=\"org.intermine.model.bio.CodingSequence\"/>" >> $outfile
            echo "      <property name=\"${source_type}.classAttribute\" value=\"primaryIdentifier\"/>" >> $outfile
            echo "      <property name=\"${source_type}.geneSource\" value=\"${gene_source}\"/>" >> $outfile
            echo "      <property name=\"${source_type}.sequenceType\" value=\"dna\"/>" >> $outfile
            echo "      <property name=\"${source_type}.includes\" value=\"*.fa\"/>" >> $outfile
            echo "      <property name=\"${source_type}.idSuffix\" value=\"-CDS\"/>" >> $outfile
            echo "      <property name=\"${source_type}.loaderClassName\" value=\"org.intermine.bio.dataconversion.CDSFastaAssemblyLoaderTask\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${dirname}/cds_fasta/${org}/${assembly}\"/>" >> $outfile
            echo "    </source>" >> $outfile

            # Protein
            echo "    <source name=\"${abbr}${append_assembly}-${dirname,,}-protein\" type=\"${source_type}\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"${source_type}.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
            echo "      <property name=\"${source_type}.dataSourceName\" value=\"${source_name}\"/>" >> $outfile
            echo "      <property name=\"${source_type}.dataSetTitle\" value=\"${fullname^} ${gene_source} Protein Sequences\"/>" >> $outfile
            echo "      <property name=\"${source_type}.className\" value=\"org.intermine.model.bio.Polypeptide\"/>" >> $outfile
            echo "      <property name=\"${source_type}.classAttribute\" value=\"primaryIdentifier\"/>" >> $outfile
            echo "      <property name=\"${source_type}.geneSource\" value=\"${gene_source}\"/>" >> $outfile
            echo "      <property name=\"${source_type}.sequenceType\" value=\"protein\"/>" >> $outfile
            echo "      <property name=\"${source_type}.includes\" value=\"*.fa\"/>" >> $outfile
            echo "      <property name=\"${source_type}.loaderClassName\" value=\"org.intermine.bio.dataconversion.ProteinFastaAssemblyLoaderTask\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${source_name}/protein_fasta/${org}/${assembly}\"/>" >> $outfile
            echo "    </source>" >> $outfile
        done
    done

    echo >> $outfile
    echo >> $outfile
}

function add_cds_protein_fasta {
    echo "+ Adding CDS/protein FASTA"

    for source_name in "$@"; do
        add_cds_protein_fasta_source $source_name
    done
}

function add_aliases {
    echo "+ Adding aliases"

    echo "    <!--Aliases-->" >> $outfile

    # Iterate over organisms
    data_subdir="alias"
    orgs=$(get_orgs "$data_subdir")
    for org in $orgs; do
        fullname=$(echo "$org" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$org")
	classname="org.intermine.model.bio.Transcript"
        num_transcripts=$(find ${mine_dir}/datasets/${data_subdir}/${org}/ -mindepth 1 -maxdepth 1 -type f -name "*map*" 2>/dev/null | wc -l)
	if [ "$num_transcripts" -eq 0 ]; then
	    classname="org.intermine.model.bio.Gene"
	fi

        echo "    <source name=\"${abbr}-aliases\" type=\"aliases\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"taxonId\" value=\"${taxon_id}\"/>" >> $outfile
	echo "      <property name=\"className\" value=\"${classname}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    done

    echo >> $outfile
    echo >> $outfile
}

function add_xrefs {
    echo "+ Adding xrefs"

    echo "    <!--xRefs-->" >> $outfile

    # Iterate over organisms
    data_subdir="xref"
    orgs=$(get_orgs "$data_subdir")
    for org in $orgs; do
        fullname=$(echo "$org" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$org")

        echo "    <source name=\"${abbr}-xref\" type=\"cross-references\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"taxonId\" value=\"${taxon_id}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    done

    echo >> $outfile
    echo >> $outfile
}

function add_kegg {
    echo "+ Adding KEGG"

    echo "    <!--KEGG-->" >> $outfile

    kegg_genes_dir="KEGG_genes"
    map_title_file="${mine_dir}/datasets/${kegg_genes_dir}/map_title.tab"
    check_file "$map_title_file"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        taxon_id_list=$(cut -f1 ${map_title_file} | sort -n | uniq | xargs)

        echo "    <source name=\"kegg\" type=\"kegg-pathway\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"pathway.organisms\" value=\"${taxon_id_list}\"/>" >> $outfile
        echo "      <property name=\"urlPrefix\" value=\"https://www.genome.jp/pathway/\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${kegg_genes_dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_reactome_gramene {
    echo "+ Adding Reactome-Gramene"

    echo "    <!--Reactome-Gramene-->" >> $outfile

    reactome_gramene_dir="reactome_pathways"
    check_dir "$reactome_gramene_dir"
    map_title_file="${mine_dir}/datasets/${reactome_gramene_dir}/map_title.tab"
    check_file "$map_title_file"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        taxon_id_list=$(cut -f1 ${map_title_file} | sort -n | uniq | xargs)

        echo "    <source name=\"reactome-gramene-pathway\" type=\"reactome-gramene\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"pathway.organisms\" value=\"${taxon_id_list}\"/>" >> $outfile
        echo "      <property name=\"urlPrefix\" value=\"https://plantreactome.gramene.org/PathwayBrowser/#/\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${reactome_gramene_dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_pubmed_source {
    source_name=$1

    pubmed_dir="ncbi-pubmed-gene"
    if [ "$source_name" == "Ensembl" ]; then
        pubmed_dir="ensembl-pubmed-gene"
    fi
    pubmed_file=$(find ${mine_dir}/datasets/${pubmed_dir} -mindepth 1 -maxdepth 1 -type f 2>/dev/null)
    check_file "$pubmed_file"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        taxon_ids=$(cut -f1 ${pubmed_file} | sort -n | uniq | xargs)

        echo "    <source name=\"${pubmed_dir,,}\" type=\"pubmed-gene\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"geneSource\" value=\"${source_name}\"/>" >> $outfile
        echo "      <property name=\"pubmed.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${pubmed_dir}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    else
        echo "WARNING: no pubmed gene data file in ${pubmed_dir}" 1>&2
    fi
}

function add_pubmed {
    echo "+ Adding PubMed"

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
    find ${mine_dir}/datasets -mindepth 1 -maxdepth 1 -type d -iname "uniprot" 2>/dev/null
}

function get_uniprot_taxon_id_list {
    dirname=$1
    find ${dirname} -type f -name "*uniprot*.xml" -printf "%f\n" 2>/dev/null | grep -Eo '[0-9]*' | sort -n | uniq | xargs
}

function add_uniprot_source {
    source_name=$1
    index=$2
    dirname=$3
    taxon_id_list=$4

    # Between one to three iterations:
    cardinal="First"
    if [ "$index" -eq "2" ]; then
        cardinal="Second"
    elif [ "$index" -eq "3" ]; then
        cardinal="Third"
    fi

    echo "    <!--${cardinal} iteration UniProt: ${source_name}-->" >> $outfile

    echo "    <source name=\"uniprot-to-${source_name,,}\" type=\"uniprot\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"uniprot.organisms\" value=\"${taxon_id_list}\"/>" >> $outfile
    echo "      <property name=\"creatego\" value=\"true\"/>" >> $outfile
    echo "      <property name=\"creategenes\" value=\"true\"/>" >> $outfile
    echo "      <property name=\"allowduplicates\" value=\"false\"/>" >> $outfile
    echo "      <property name=\"loadfragments\" value=\"true\"/>" >> $outfile
    echo "      <property name=\"loadtrembl\" value=\"true\"/>" >> $outfile
    echo "      <property name=\"configFile\" value=\"uniprot-to-${source_name,,}_config.properties\"/>" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${dirname}\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
}

function add_uniprot_fasta {
    dirname=$1
    taxon_id_list=$2

    echo "    <!--UniProt-Fasta-->" >> $outfile

    echo "    <source name=\"uniprot-fasta\" type=\"fasta\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"fasta.taxonId\" value=\"${taxon_id_list}\"/>" >> $outfile
    echo "      <property name=\"fasta.className\" value=\"org.intermine.model.bio.Protein\"/>" >> $outfile
    echo "      <property name=\"fasta.classAttribute\" value=\"primaryAccession\"/>" >> $outfile
    echo "      <property name=\"fasta.dataSourceName\" value=\"UniProt\"/>" >> $outfile
    echo "      <property name=\"fasta.dataSetTitle\" value=\"UniProt Fasta\"/>" >> $outfile
    echo "      <property name=\"fasta.includes\" value=\"uniprot_sprot_varsplic.fasta\"/>" >> $outfile
    echo "      <property name=\"fasta.sequenceType\" value=\"protein\"/>" >> $outfile
    echo "      <property name=\"fasta.loaderClassName\" value=\"org.intermine.bio.dataconversion.UniProtFastaLoaderTask\"/>" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${dirname}\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
}

function add_uniprot_keywords {
    dirname=$1
    taxon_id_list=$2

    echo "    <!--UniProt-keywords-->" >> $outfile

    echo "    <source name=\"uniprot-keywords\" type=\"uniprot-keywords\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${dirname}\"/>" >> $outfile
    echo "      <property name=\"src.data.dir.includes\" value=\"keywlist.xml\"/>" >> $outfile
    echo "    </source>" >> $outfile
}

function add_uniprot {
    echo "+ Adding UniProt"

    echo "    <!--UniProt-->" >> $outfile
    echo >> $outfile

    # Get UniProt directory name (case varies)
    dirname=$(get_uniprot_dir_name)
    check_dir "$dirname"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        # Get taxon id list from UniProt filenames
        taxon_id_list=$(get_uniprot_taxon_id_list "$dirname")
        if [ -z "$taxon_id_list" ]; then
            echo "WARNING: UniProt taxon id list is empty" 1>&2
            return 1
        fi

        index=1
        for source_name in "$@"; do
            add_uniprot_source "$source_name" "$index" "$dirname" "$taxon_id_list" 
            index=$((index+1))
        done

        # UniProt FASTA
        add_uniprot_fasta "$dirname" "$taxon_id_list" 

        # UniProt keywords
        add_uniprot_keywords "$dirname" "$taxon_id_list" 
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_faang_gff {
    echo "+ Adding FAANG GFF"

    echo "    <!--FAANG GFF-->" >> $outfile
    echo "    <!--No Gene.source so load these here (not with rest of GFFs)-->" >> $outfile

    # Iterate over organisms
    data_subdir="FAANG-gff"
    orgs=$(get_orgs "$data_subdir")
    for org in $orgs; do
        fullname=$(echo "$org" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$org")
        # Iterate over assemblies (usually just one)
        assemblies=$(get_assemblies "${data_subdir}/${org}")
        num_assemblies=$(echo "$assemblies" | wc -l)
        for assembly in $assemblies; do
            # If multiple assemblies, append assembly version to source name
            append_assembly=$(get_append_assembly "$assembly" "$num_assemblies")
            echo "    <source name=\"${abbr}${append_assembly}-faang-gff\" type=\"faang-gff\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
            echo "      <property name=\"gff3.dataSourceName\" value=\"FAANG\"/>" >> $outfile
            echo "      <property name=\"gff3.dataSetTitle\" value=\"${fullname^} FAANG data from FAANG.org data set\"/>" >> $outfile
            echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
            echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}/${assembly}\"/>" >> $outfile
            echo "    </source>" >> $outfile
        done
    done

    echo >> $outfile
    echo >> $outfile
}

function add_qtl_gff {
    echo "+ Adding QTL GFF"

    echo "    <!--QTL GFF-->" >> $outfile
    echo "    <!--No Gene.source so load these here (not with rest of GFFs)-->" >> $outfile

    # Iterate over organisms
    data_subdir="QTL"
    orgs=$(get_orgs "$data_subdir")
    for org in $orgs; do
        fullname=$(echo "$org" | sed 's/_/ /'g)
        taxon_id=$(grep -i "$fullname" taxon_ids.tab | cut -f2)
        abbr=$(get_abbr "$org")
        # Iterate over assemblies (usually just one)
        assemblies=$(get_assemblies "${data_subdir}/${org}")
        num_assemblies=$(echo "$assemblies" | wc -l)
        for assembly in $assemblies; do
            # If multiple assemblies, append assembly version to source name
            append_assembly=$(get_append_assembly "$assembly" "$num_assemblies")
            echo "    <source name=\"${abbr}${append_assembly}-qtl-gff\" type=\"qtl-gff\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"gff3.taxonId\" value=\"${taxon_id}\"/>" >> $outfile
            echo "      <property name=\"gff3.dataSourceName\" value=\"Animal QTLdb\"/>" >> $outfile
            echo "      <property name=\"gff3.dataSetTitle\" value=\"${fullname^} QTL from Animal QTLdb data set\"/>" >> $outfile
            echo "      <property name=\"gff3.seqClsName\" value=\"Chromosome\"/>" >> $outfile
            echo "      <property name=\"gff3.seqAssemblyVersion\" value=\"${assembly}\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${data_subdir}/${org}/${assembly}\"/>" >> $outfile
            echo "    </source>" >> $outfile
        done
    done

    echo >> $outfile
    echo >> $outfile
}

function get_interpro_dir_name {
    # Folder name could be InterPro or interpro
    find ${mine_dir}/datasets -mindepth 1 -maxdepth 1 -type d -iname "interpro" -printf "%f\n"
}

function add_interpro {
    echo "+ Adding InterPro"

    echo "    <!--InterPro-->" >> $outfile

    dirname=$(get_interpro_dir_name)
    if [ -z "$dirname" ]; then
        echo "WARNING: InterPro data directory does not exist" 1>&2
        return 1
    fi

    echo "    <source name=\"interpro\" type=\"interpro\" version=\"${source_version}\">" >> $outfile
    echo "      <property name=\"src.data.dir\" location=\"${mine_dir}/datasets/${dirname}\"/>" >> $outfile
    echo "    </source>" >> $outfile

    echo >> $outfile
    echo >> $outfile
}

function add_protein2ipr {
    echo "+ Adding InterPro to protein (protein2ipr)"

    echo "    <!--InterPro to protein (protein2ipr)-->" >> $outfile

    dirname="${mine_dir}/datasets/protein2ipr"
    check_dir "$dirname"
    filename="protein2ipr.dat"
    check_file "${dirname}/$filename"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        echo "    <source name=\"protein2ipr\" type=\"protein2ipr\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${dirname}\"/>" >> $outfile
        echo "      <property name=\"includes\" value=\"${filename}\"/>" >> $outfile
        echo "      <property name=\"osAlias\" value=\"os.production\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_reactome {
    echo "+ Adding Reactome"

    echo "    <!--Reactome-->" >> $outfile

    taxon_ids="$1"
    dirname="${mine_dir}/datasets/Reactome"
    check_dir "$dirname"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        echo "    <source name=\"reactome\" type=\"reactome\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${dirname}\"/>" >> $outfile
        echo "      <property name=\"reactome.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_biogrid {
    echo "+ Adding BioGRID"

    echo "    <!--BioGRID-->" >> $outfile

    dirname="${mine_dir}/datasets/BioGRID"
    check_dir "$dirname"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        taxon_label="NCBITax:"
        taxon_ids=$(grep -rsoE "${taxon_label}\s+[0-9]+" ${mine_dir}/datasets/BioGRID/ | awk -F"${taxon_label}" '{print $2}' | sort -n | xargs)

        echo "    <source name=\"biogrid\" type=\"biogrid\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${dirname}\"/>" >> $outfile
        echo "      <property name=\"src.data.dir.includes\" value=\"*.xml\"/>" >> $outfile
        echo "      <property name=\"biogrid.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_intact {
    taxon_ids=$1

    echo "+ Adding IntAct"

    echo "    <!--IntAct-->" >> $outfile

    dirname="${mine_dir}/datasets/IntAct"
    check_dir "$dirname"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        echo "    <source name=\"psi-intact\" type=\"psi\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${dirname}\"/>" >> $outfile
        echo "      <property name=\"intact.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_orthodb {
    echo "+ Adding OrthoDB"

    echo "    <!--OrthoDB-->" >> $outfile
    echo "    <!--Data file(s) must be sorted on column 2 before loading!-->" >> $outfile

    dirname="${mine_dir}/datasets/OrthoDB"
    check_dir "$dirname"
    ec=$?
    if [ "$ec" -eq 0 ]; then
	# Check that directory has .tab files
	num_files=$(find "${dirname}/" -mindepth 1 -maxdepth 1 -type f -name "*.tab" 2>/dev/null | wc -l)
        if [ "$num_files" -ne 0 ]; then
            taxon_ids=$(awk -F'\t' '{print $6}' ${dirname}/*.tab  | sort -n | uniq | xargs)

            echo "    <source name=\"orthodb\" type=\"orthodb-clusters\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"dataSourceName\" value=\"OrthoDB\"/>" >> $outfile
            echo "      <property name=\"dataSetTitle\" value=\"OrthoDB data set\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${dirname}\"/>" >> $outfile
            echo "      <property name=\"orthodb.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
            echo "    </source>" >> $outfile
	fi
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_hgd_ortho {
    echo "+ Adding HGD-Ortho"

    echo "    <!--HGD-Ortho-->" >> $outfile
    echo "    <!--Data file(s) must be sorted on column 2 before loading!-->" >> $outfile

    dirname="${mine_dir}/datasets/HGD-Ortho"
    check_dir "$dirname"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        # Check that directory has .tab files
        num_files=$(find "${dirname}/" -mindepth 1 -maxdepth 1 -type f -name "*.tab" 2>/dev/null | wc -l)
        if [ "$num_files" -ne 0 ]; then
            taxon_ids=$(awk -F'\t' '{print $6}' ${dirname}/*.tab  | sort -n | uniq | xargs)
   
            echo "    <source name=\"hgd-ortho\" type=\"orthodb-clusters\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"dataSourceName\" value=\"HGD\"/>" >> $outfile
            echo "      <property name=\"dataSetTitle\" value=\"HGD-Ortho data set\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${dirname}\"/>" >> $outfile
            echo "      <property name=\"orthodb.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
            echo "    </source>" >> $outfile
        fi
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_ensembl_compara {
    echo "+ Adding EnsemblCompara"

    echo "    <!--EnsemblCompara-->" >> $outfile

    dirname="${mine_dir}/datasets/EnsemblCompara"
    check_dir "$dirname"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        # Get taxon ID list
        taxon_ids=$(find ${dirname} -type f -printf '%f\n' | awk -F'_' '{printf "%s\\n\n%s\\n\n", $1, $2}' 2>/dev/null | sed 's/\\n//g' | sort -n | uniq | xargs)
        if [ ! -z "$taxon_ids" ] ; then
            echo "    <source name=\"ensembl-compara\" type=\"ensembl-compara\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"ensemblcompara.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
            echo "      <property name=\"ensemblcompara.homologues\" value=\"${taxon_ids}\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${dirname}\"/>" >> $outfile
            echo "    </source>" >> $outfile
        else
            echo "WARNING: EnsemblCompara taxon id list is empty" 1>&2
        fi
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_biomart {
    echo "+ Adding Ensembl Plant BioMart"

    echo "    <!--Ensembl Plant BioMart-->" >> $outfile

    dirname="${mine_dir}/datasets/ensembl-plant-biomart"
    check_dir "$dirname"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        # Get taxon ID list
        homologues_dir="$dirname/homologues"
        taxon_ids=$(find ${homologues_dir} -type f -printf '%f\n' | awk -F'_' '{printf "%s\\n\n%s\\n\n", $1, $2}' 2>/dev/null | sed 's/\\n//g' | sort -n | uniq | xargs)
        if [ ! -z "$taxon_ids" ] ; then
            echo "    <source name=\"biomart\" type=\"ensembl-compara\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"ensemblcompara.organisms\" value=\"${taxon_ids}\"/>" >> $outfile
            echo "      <property name=\"ensemblcompara.homologues\" value=\"${taxon_ids}\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${dirname}/homologues\"/>" >> $outfile
            echo "    </source>" >> $outfile
            echo "    <!--Symbols-->" >> $outfile
            echo "    <source name=\"gene-symbols\" type=\"additional-gene-attributes\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"attributeName\" value=\"symbol\"/>" >> $outfile
            echo "      <property name=\"dataSourceName\" value=\"Ensembl\"/>" >> $outfile
            echo "      <property name=\"dataSetTitle\" value=\"Ensembl Plant BioMart symbols data set\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${dirname}/symbols\"/>" >> $outfile
            echo "      <property name=\"src.data.dir.includes\" value=\".tab\"/>" >> $outfile
            echo "    </source>" >> $outfile
            echo "    <!--Descriptions-->" >> $outfile
            echo "    <source name=\"gene-descriptions\" type=\"additional-gene-attributes\" version=\"${source_version}\">" >> $outfile
            echo "      <property name=\"attributeName\" value=\"description\"/>" >> $outfile
            echo "      <property name=\"dataSourceName\" value=\"Ensembl\"/>" >> $outfile
            echo "      <property name=\"dataSetTitle\" value=\"Ensembl Plant BioMart descriptions data set\"/>" >> $outfile
            echo "      <property name=\"src.data.dir\" location=\"${dirname}/descriptions\"/>" >> $outfile
            echo "      <property name=\"src.data.dir.includes\" value=\".tab\"/>" >> $outfile
            echo "    </source>" >> $outfile
        else
            echo "WARNING: Ensembl Plant BioMart taxon id list is empty" 1>&2
        fi
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_omim {
    echo "+ Adding OMIM"

    echo "    <!--OMIM-->" >> $outfile

    dirname="${mine_dir}/datasets/omim"
    check_dir "$dirname"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        echo "    <source name=\"omim\" type=\"omim\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.dir\" location=\"${dirname}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_update_data_sources {
    echo "+ Adding Update Data Sources"

    echo "    <!--Load these last sources at the end, after all other sources-->" >> $outfile

    echo >> $outfile
    echo >> $outfile

    echo "    <!--Update data sources-->" >> $outfile

    dirname=$(get_uniprot_dir_name)
    filename="${dirname}/xrefs/dbxref.txt"
    check_file "$filename"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        echo "    <source name=\"update-data-sources\" type=\"update-data-sources\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.file\" location=\"datasources.xml\"/>" >> $outfile
        echo "      <property name=\"dataSourceFile\" value=\"${filename}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi

    filename="${mine_dir}/datasets/datasource-info/customsources.txt"
    check_file "$filename"
    ec=$?
    if [ "$ec" -eq 0 ]; then
        echo "    <!--Custom data source info not in UniProt file-->" >> $outfile
        echo "    <source name=\"update-data-sources-custom\" type=\"update-data-sources\" version=\"${source_version}\">" >> $outfile
        echo "      <property name=\"src.data.file\" location=\"datasources-custom.xml\"/>" >> $outfile
        echo "      <property name=\"dataSourceFile\" value=\"${filename}\"/>" >> $outfile
        echo "    </source>" >> $outfile
    fi

    echo >> $outfile
    echo >> $outfile
}

function add_ncbi_entrez {
    echo "+ Adding NCBI Entrez"

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

function add_post_processes {
    echo "+ Adding Post-processing"

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

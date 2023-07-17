#!/usr/bin/python

import logging
import csv
import re
import argparse

##################################################
#                                                #
#   TO BEGIN: set filename and header widths!!   #
#                                                #
##################################################

def getFilename(mineName, mineVersion):
    # Set a custom filename here if not using default
    # filename = "MaizeMine_v1.4_Data_Sources.csv"
    filename = mineName + '_v' + mineVersion + '_Data_Sources.csv'
    return 'input_csv/' + filename


def getHeaderWidths(mineName):
    # Set header widths here if not using default
    # return ['15%', '25%', '10%', '15%', '20%', '15%'] # should add up to 100%
    # So far these don't vary much by version, so just use Mine name:
    headerWidthsForMine = {
        'AquaMine': ['10%', '15%', '22%', '23%', '20%', '10%'],
        'FAANGMine': ['15%', '15%', '10%', '25%', '25%', '10%'],
        'HymenopteraMine': ['15%', '15%', '15%', '25%', '20%', '10%'],
        'MaizeMine': ['15%', '15%', '15%', '20%', '20%', '15%']
    }
    return headerWidthsForMine[mineName]


##################################################

# Cheat sheet:
# * HTML allowed in cells (<br>, <b>, etc.)
# * Vertically adjacent cells with same content will be merged;
#   add "*" in front of 2nd and onward cells to prevent this.
#   Horizontally adjacent cells with same content will also be merged;
#   similarly add "*" in front of 2nd and onward column cells to prevent this.
#   In other words, any cell with "*" in front will never be merged with any
#   other row or column.
#   The '*' prefix itself will not appear in the final table output.
# * "PubMed: #########" numbers will be replaced with link to pubmed.
# * Check links below in formatText(), may need to be customized per mine.

##################################################

def checkVersionNumber(inputStr):
    # Our version number format: X.Y where X, Y are integers
    vs = inputStr.split('.')
    if (len(vs) != 2 or any([not i.isdigit() for i in vs])):
        raise argparse.ArgumentTypeError("%s is not a valid version number" % inputStr)
    return inputStr
    

def parse_args():
    parser = argparse.ArgumentParser(description='Convert Data sources table CSV to HTML.')
    parser.add_argument('mine', choices=['AquaMine', 'FAANGMine', 'HymenopteraMine', 'MaizeMine'], help='Name of mine (required)')
    parser.add_argument('version', type=checkVersionNumber, help='Mine version, e.g., 1.6 (required)')
    args = parser.parse_args()
    return args
    

def getHTMLFileTop():
    return "<html><head>\n<title>Data Categories Table</title>\n<style>\nbody {\nfont-family: 'Lucida Grande', Verdana, Geneva, Lucida, Helvetica, Arial, sans-serif;\ncolor: #333333;\n}\ntable {\nborder-left: 1px solid #333!important;\nborder-right:1px solid #333;\nborder-bottom:1px solid #333\n}\ntable {\nwidth: 96%;\nmargin-left: 2%;\nmargin-right: 2%;\nmargin-top: 2%;\nmargin-bottom: 2%;\n}\ntd, th {\npadding: 6px 6px 6px 12px;\nborder-right: 1px solid #333;\nborder-bottom: 1px solid #333;\nfont-size: 12px;\n}\nth {\npadding: 6px 6px 6px 12px;\ntext-align: left;\nfont-weight: bold;\nborder-right: 1px solid #FFFFFF!important;\ncolor: white;\nbackground-color: #000;\n}\ntr.new-category-row td {\nborder-top: 1px solid #333}\ntd.leftcol {\nborder-left:1px solid #333}\ntd.last-child {\nborder-right:1px solid #333}\n</style></head>\n<body>\n\n"

def getHTMLFileBottom():
    return "</body>\n</html>"

# These have to be updated with each release
# TODO: Move these to a separate input file (per mine?)
def formatText(text):
    # Check for special cases where additional formatting (e.g., add URL link) is needed
    # 1) look for PubMed links:
    if ("PubMed" in text):
        text = addPubMedLink(text)
    # 2) look for other common links:
    linksWithinText = {
        "data usage at HGD" : "http://hymenopteragenome.org/data_usage_citing"
    }
    linksExactMatch = {
        # Ontologies:
        "ATOL"                            : "https://bioportal.bioontology.org/ontologies/ATOL",
        "BTO"                             : "https://bioportal.bioontology.org/ontologies/BTO",
        "CL"                              : "https://obophenotype.github.io/cell-ontology/",
        "CMO"                             : "https://bioportal.bioontology.org/ontologies/CMO",
        "ECO"                             : "https://bioportal.bioontology.org/ontologies/ECO",
        "EFO"                             : "https://www.ebi.ac.uk/efo/index.html",
        "EOL"                             : "https://bioportal.bioontology.org/ontologies/EOL",
        "GO"                              : "https://bioportal.bioontology.org/ontologies/GO",
        "HAO"                             : "https://bioportal.bioontology.org/ontologies/HAO",
        "HSAPDV"                          : "https://bioportal.bioontology.org/ontologies/HSAPDV",
        "HP"                              : "https://hpo.jax.org/app/data/ontology",
        "LBO"                             : "https://bioportal.bioontology.org/ontologies/LBO",
        "LPT"                             : "https://bioportal.bioontology.org/ontologies/LPT",
        "MA"                              : "https://bioportal.bioontology.org/ontologies/MA",
        "MONDO"                           : "https://mondo.monarchinitiative.org/pages/download/",
        "MI"                              : "https://bioportal.bioontology.org/ontologies/PSIMOD",
        "OBI"                             : "http://obi-ontology.org",
        "ORDO"                            : "https://bioportal.bioontology.org/ontologies/ORDO",
        "PATO"                            : "https://github.com/pato-ontology/pato/",
        "PO"                              : "https://bioportal.bioontology.org/ontologies/PO",
        "PSI-MI"                          : "https://github.com/HUPO-PSI/psi-mi-CV",
        "SO"                              : "https://bioportal.bioontology.org/ontologies/SO",
        "UBERON"                          : "https://bioportal.bioontology.org/ontologies/UBERON",
        "VT"                              : "https://bioportal.bioontology.org/ontologies/VT",
        # Other sources:
        "Ensembl Plants BioMart Download" : "http://plants.ensembl.org/index.html",
        "GOA UniProt FTP"                 : "http://ftp.ebi.ac.uk/pub/databases/GO/goa/UNIPROT/goa_uniprot_all.gaf.gz",
        "GO Consortium Annotation FTP"    : "http://geneontology.org/page/download-ontology",
        "GOC Download"                    : "http://geneontology.org/docs/download-ontology",
        "HGD"                             : "http://hymenopteragenome.org",
        "HGD Genome Fasta Download"       : "http://hymenopteragenome.org/genome_fasta",
        "HGD GO Annotation Download"      : "http://hymenopteragenome.org/hgd-go-annotation",
        "HGD OGS GFF3 Download"           : "http://hymenopteragenome.org/ogs_gff3_files",
        "HGD Ortholog Download"           : "http://hymenopteragenome.org/orthologs",
        "KEGG Download"                   : "https://www.kegg.jp/kegg/rest/keggapi.html",
        "NCBI PubMed FTP"                 : "https://ftp.ncbi.nlm.nih.gov/gene/DATA/gene2pubmed.gz",
        "OMIM Download"                   : "https://www.omim.org/downloads",
        "OrthoDB"                         : "https://www.orthodb.org/",
        "OrthoDB Download"                : "https://data.orthodb.org/download/",
        "Plant Reactome Gramene Download" : "https://plantreactome.gramene.org/download/current/Ensembl2PlantReactome_All_Levels.txt",
        "QTL Download"                    : "https://www.animalgenome.org/cgi-bin/QTLdb/index",
        "Reactome Download"               : "https://reactome.org/download/current/UniProt2Reactome_All_Levels.txt",
        "TreeFam Download"                : "http://www.treefam.org/download",
        "UniProt FTP"                     : "https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/",
        # Maize Community datasets:
        "MaizeGDB Expression Download"   : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/MaizeGDB_qTeller_FPKM/B73v5_qTeller_FPKM",
        "Grotewold CAGE Tag Count Root Download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_TSS",
        "Grotewold CAGE Tag Count Shoot Download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_TSS",
        "GWAS Atlas Download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_diversity_markers_and_GWAS/GWAS/SNPs_from_GWAS_Atlas_database",
        "MaizeGDB_UniformMu Download" : "https://download.maizegdb.org/Insertions/UniformMu/",
        "Stam 2017 Husk H3K9ac Enhancer Download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_epigenetics_and_DNA_binding/Oka_2017_enhancer_binding/Oka_Enhancer_Husk_v5.gff",
        "Stam 2017 Seedling H3K9ac Enhancer Download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_epigenetics_and_DNA_binding/Oka_2017_enhancer_binding/Oka_Enhancer_Seedling_v5.gff",
        "Vollbrecht 2010 Ac/Ds Insertions Download" : "https://download.maizegdb.org/Insertions/AcDs_Vollbrecht/",
        "Wallace 2014 GWAS Download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_diversity_markers_and_GWAS/GWAS/GWAS_SNPs_from_Wallace_2014/B73v5_Wallace_etal_2014_PLoSGenet_GWAS_hits-150112_blastn.gff.gz",
    }
    for linkText, url in linksWithinText.items():
        if (linkText in text):
            text = text.replace(linkText, createURL(linkText, url, True))
    for linkText, url in linksExactMatch.items():
        if (linkText == text):
            text = text.replace(linkText, createURL(linkText, url, True))
    # 3) convert download/FTP urls to links, if applicable:
    text = addDownloadLinks(text)

    return text


def addDownloadLinks(text):
    if (len(text) > 26 and (text[0:26] == "ftp://ftp.ncbi.nlm.nih.gov")):
        text = createURL("NCBI FTP", text, True)
    if (len(text) > 28 and (text[0:28] == "https://ftp.ncbi.nlm.nih.gov")):
        text = createURL("NCBI FTP", text, True)
    if (len(text)> 23 and (text[0:23] == "https://ftp.uniprot.org")):
        text = createURL("UniProt FTP", text, True)
    if (len(text) > 44 and (text[0:44] == "https://ftp.ebi.ac.uk/pub/databases/interpro")):
        text = createURL("InterPro FTP", text, True)
    if (len(text) > 40 and (text[0:40] == "ftp://ftp.ebi.ac.uk/pub/databases/IntAct")):
        text = createURL("IntAct Download", text, True)
    if (len(text) > 42 and (text[0:42] == "https://ftp.ebi.ac.uk/pub/databases/IntAct")):
        text = createURL("IntAct Download", text, True)
    if (len(text) > 39 and (text[0:39] == "https://ftp.ebi.ac.uk/pub/databases/eva")):
        text = createURL("EVA Download", text, True)   
    if (len(text) > 30 and (text[0:30] == "https://ftp.ensemblgenomes.org")):
        text = createURL("Ensembl Genomes FTP", text, True)
    if (len(text) > 23 and (text[0:23] == "https://ftp.ensembl.org")):
        text = createURL("Ensembl FTP", text, True)
    if (len(text) > 22 and (text[0:22] == "http://ftp.ensembl.org")):
        text = createURL("Ensembl FTP", text, True)
    if (len(text) > 36 and (text[0:36] == "https://ftp.ebi.ac.uk/ensemblgenomes")):
        text = createURL("Ensembl FTP", text, True)
    if (len(text) > 26 and (text[0:26] == "https://useast.ensembl.org")):
        text = createURL("Ensembl Download", text, True)
    if (len(text) > 41 and (text[0:41] == "https://ftp.ensembl.org/pub/rapid-release")):
        text = createURL("Ensembl Rapid Release FTP", text, True)
    if (len(text) > 40 and (text[0:40] == "https://downloads.thebiogrid.org/BioGRID")):
        text = createURL("BioGRID Download", text, True)
    if (len(text) > 39 and (text[0:39] == "https://www.ncbi.nlm.nih.gov/bioproject")):
        text = createURL("NCBI BioProject", text, True) 
    if (len(text) > 30 and (text[0:30] == "https://data.faang.org/dataset")):
        text = createURL("FAANG Data Portal", text, True)
    if (len(text) > 29 and (text[0:29] == "https://download.maizegdb.org")):
        text = createURL("MaizeGDB Download", text, True)
    if (len(text) > 31 and (text[0:31] == "http://ftp.flybase.net/releases")):
        text = createURL("FlyBase Download", text, True)

    return text


def addPubMedLink(text):
    # Text contains at least one substring of the form PubMed: ####### (PMID number)
    # Get the PMIDs and create URLs
    # Return string with URL added
    
    # Search substring for the PMID using a regular expression
    pmidSubStrArr = re.findall('PubMed.*? ([0-9]+)', text)
    for pmidSubStr in pmidSubStrArr:
        text = text.replace(pmidSubStr, createURL(pmidSubStr, "https://www.ncbi.nlm.nih.gov/pubmed/" + pmidSubStr, True))

    return text


def createURL(linkText, url, newWindow):
    link = '<a href="' + url + '"'
    if (newWindow):
        link += ' target="_blank"'
    link += '>' + linkText + '</a>'
    return link


def main():
    # Get arguments
    args = parse_args()
    mineName = args.mine
    mineVersion = args.version
    filename = getFilename(mineName, mineVersion)
    
    tableRows = [] # initialize array
    headerRow = [] # header row array
    HTMLStr = ""   # initialize HTML output
    
    headerWidths = getHeaderWidths(mineName)

    # Read table from CSV
    with open(filename, 'rU') as csvfile:
        headerRow = next(csvfile).split(',')
        dataTable = csv.reader(csvfile, delimiter=',')
        for rowNum, row in enumerate(dataTable):
            tableRows.append([])  # add empty array
            colSpan = 1  # Initialize colspan for entire row
            for colNum, col in enumerate(row):
                # Remove any line breaks from end of text
                col = col.rstrip('\n')
                
                # Initialize dictionary
                colVals = {}
                colVals['text'] = col
                colVals['spansRows'] = False
                colVals['rowSpan'] = 1
                colVals['spanStartRow'] = -1
                colVals['spansCols'] = False
                colVals['colSpan'] = 1
                colVals['spanStartCol'] = -1

                # Check if this column is part of a col span, and if so, update variables
                # Note that an asterisk (*) in front denotes keep columns separate even if it matches previous column
                if ((colNum > 1) and (col) and (col[0] != '*') and (col == tableRows[rowNum][colNum - 1]['text'])):
                    # Text in this column matches text from previous column in same row, so combine into colspan
                    colVals['spansCols'] = True
                    spanStartCol = 0 # initialize
                    # Determine which column is the start of the span:
                    if (tableRows[rowNum][colNum - 1]['spanStartCol'] > -1):
                        # tableRows[rowNum][colNum - 1]["spanStartCol"] already points to first col of span
                        spanStartCol = tableRows[rowNum][colNum - 1]["spanStartCol"]
                    else:
                        # Previous column is the start of the span
                        spanStartCol = colNum - 1
                        # Update previous column in this row to indicate it's part of a span
                        tableRows[rowNum][colNum - 1]['spansCols'] = True
                    # Increment colSpan count for the first col in the span
                    tableRows[rowNum][spanStartCol]['colSpan'] += 1
                    # Set this so next column will know which colSpan count to update too
                    colVals['spanStartCol'] = spanStartCol
                    # Don't remove asterisk yet, will need to denote separate row below

                # Check if this column is part of a row span, and if so, update variables
                # Note that an asterisk (*) in front denotes keep separate row even if it matches the row above
                if ((rowNum > 0) and (col) and (col[0] != '*') and (col == tableRows[rowNum - 1][colNum]['text'])):
                    # Text in this column matches text from same column in previous row,
                    # so combine them into one rowspan
                    # First indicate that this column is part of a colspan:
                    colVals['spansRows'] = True
                    spanStartRow = 0  # initialize
                    # Determine which row is the start of the span:
                    if (tableRows[rowNum - 1][colNum]['spanStartRow'] > -1):
                        # tableRows[rowNum - 1][colNum]["spanStartRow"] already points to first row of span
                        spanStartRow = tableRows[rowNum - 1][colNum]['spanStartRow']
                    else:
                        # Previous row is the start of the span
                        spanStartRow = rowNum - 1
                        # Update col in previous row to indicate it's part of a span
                        tableRows[rowNum - 1][colNum]['spansRows'] = True
                    # Increment the rowSpan count for the first row in the span
                    tableRows[spanStartRow][colNum]['rowSpan'] += 1
                    # Set this so next row will know which rowSpan count to update too
                    colVals['spanStartRow'] = spanStartRow
                elif ((col) and (col[0] == '*')):
                    # Safe to remove asterisk now
                    colVals['text'] = col[1:]

                # Add column values dictionary to array
                tableRows[rowNum].append(colVals)

    # Create HTML from table
    outfile = 'output_html/dataSourcesTable_' + mineName + '_v' + mineVersion + '.html'
    with open(outfile, 'w') as HTMLfile:
        # Print top of HTML file
        HTMLfile.write(getHTMLFileTop())
        # Open table tag
        HTMLfile.write('<table cellpadding="0" cellspacing="0" border="0" class="dbsources">')
        # Create header row
        HTMLfile.write('<tr>')
        for idx, headerCol in enumerate(headerRow):
            HTMLfile.write('<th width="' + headerWidths[idx] + '">' + headerCol + '</th>')
        HTMLfile.write('</tr>')
        # Create data rows
        prevCategory = tableRows[0][0]['text']
        for rowNum, row in enumerate(tableRows):
            # Open row tag
            HTMLfile.write('<tr')
            curCategory = tableRows[rowNum][0]['text']
            if (curCategory == prevCategory):
                # Still in same category (Genes, Proteins, etc.)
                # Finish <tr> tag with no special class
                HTMLfile.write('>\n')
            else:
                # New category, add row class
                HTMLfile.write(' class="new-category-row">\n')
                prevCategory = curCategory
            for colNum, col in enumerate(row):
                if (col['spansRows'] and col['rowSpan'] <= 1):
                    # If middle row of spanning column, don't create <td> at all, just put in placeholder comment
                    HTMLfile.write('<!-- part of rowspan -->')
                elif (col['spansCols'] and col['colSpan'] <= 1):
                    # If middle of spanning row, similarly don't create <td> at all
                    HTMLfile.write('<!-- part of colspan -->')
                else:
                    # Create the <td> column:
                    colText = col['text'] # cell contents
                    
                    HTMLfile.write('<td') # begin column tag
                    
                    if (colNum == 0):
                        # Add leftcol class to first column
                        HTMLfile.write(' class="leftcol"')
                    if (col['spansRows'] and col['rowSpan'] > 1):
                        # First row of spanning column, add rowspan
                        HTMLfile.write(' rowspan="' + str(col['rowSpan']) + '"')
                    if (col['spansCols'] and col['colSpan'] > 1):
                        # First row of spanning row, add colspan
                        HTMLfile.write(' colspan="' + str(col['colSpan']) + '"')
                    
                    HTMLfile.write('>') # End row tag
                    
                    # Add extra formatting to text if necessary
                    text = formatText(col['text'])
                    
                    # If first column, add <h2> and <p> tags to text
                    if (colNum == 0):
                        HTMLfile.write('<h2><p>')
                    
                    # Add the column text
                    HTMLfile.write(text)
                    
                    # If first column, close <h2> and <p> tags
                    if (colNum == 0):
                        HTMLfile.write('</p></h2>')
                    
                    # Close the <td> tag
                    HTMLfile.write('</td>')
                    
                HTMLfile.write('\n')
                
            # Close row tag
            HTMLfile.write('</tr>\n')

        # Close table tag
        HTMLfile.write('</table>\n\n')

        # Print bottom of HTML file
        HTMLfile.write(getHTMLFileBottom())

    print "Created HTML file " + outfile


if __name__ == "__main__":
    main()

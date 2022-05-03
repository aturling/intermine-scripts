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
        'MaizeMine': ['15%', '25%', '10%', '15%', '20%', '15%']
    }
    return headerWidthsForMine[mineName]


##################################################

# Cheat sheet:
# * HTML allowed in cells (<br>, <b>, etc.)
# * Vertically adjacent cells with same content will be merged;
#   add "*" in front of 2nd and onward cells to prevent this.
# * "PubMed: #########" numbers will be replaced with link to pubmed.
# * Check links below in formatText(), may need to be customized per mine.
# * Links beginning with "ftp://ftp.ncbi.nlm.nih.gov" or
#   "https://ftp.ncbi.nlm.nih.gov" can be put straight into
#   the cell with no formatting and will be converted to "NCBI FTP" with link.

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
        "BTO"                            : "https://bioportal.bioontology.org/ontologies/BTO",
        "CMO"                            : "https://bioportal.bioontology.org/ontologies/CMO",
        "ECO"                            : "https://bioportal.bioontology.org/ontologies/ECO",
        "GO"                             : "https://bioportal.bioontology.org/ontologies/GO",
        "HAO"                            : "http://www.obofoundry.org/ontology/hao.html",
        "LBO"                            : "https://bioportal.bioontology.org/ontologies/LBO",
        "LPT"                            : "https://bioportal.bioontology.org/ontologies/LPT",
        "MA"                             : "https://bioportal.bioontology.org/ontologies/MA",
        "MI"                             : "https://bioportal.bioontology.org/ontologies/PSIMOD",
        "PO"                             : "https://github.com/Planteome/plant-ontology",
        "SO"                             : "http://intermine.org/im-docs/docs/database/data-sources/library/so",
        "UBERON"                         : "http://purl.obolibrary.org/obo/uberon/basic.obo",
        "VT"                             : "https://bioportal.bioontology.org/ontologies/VT",
        # Other sources:
        "BioGRID Download"               : "https://downloads.thebiogrid.org/BioGRID/Release-Archive/BIOGRID-3.5.187/",
        "Ensembl Plant Biomart download" : "http://plants.ensembl.org/index.html",
        "FAANG Download"                 : "https://data.faang.org/dataset/PRJEB35307",
        "GOA UniProt FTP"                : "http://ftp.ebi.ac.uk/pub/databases/GO/goa/UNIPROT/goa_uniprot_all.gaf.gz",
        "GO Consortium Annotation FTP"   : "http://geneontology.org/page/download-ontology",
        "GOC Download"                   : "http://geneontology.org/docs/download-ontology",
        "HGD"                            : "http://hymenopteragenome.org",
        "HGD Genome Fasta Download"      : "http://hymenopteragenome.org/genome_fasta",
        "HGD OGS GFF3 Download"          : "http://hymenopteragenome.org/ogs_gff3_files",
        "IntAct FTP"                     : "ftp://ftp.ebi.ac.uk/pub/databases/IntAct/current/",
        "InterPro FTP"                   : "http://ftp.ebi.ac.uk/pub/databases/interpro/88.0/",
        "KEGG Download"                  : "https://www.kegg.jp/kegg/rest/keggapi.html",
        "NCBI PubMed FTP"                : "https://ftp.ncbi.nlm.nih.gov/gene/DATA/gene2pubmed.gz",
        "OMIM Download"                  : "https://www.omim.org/downloads",
        "OrthoDB Download"               : "https://www.orthodb.org",
        "Plant Reactome Gramene FTP"     : "https://plantreactome.gramene.org/index.php?lang=en",
        "QTL Download"                   : "https://www.animalgenome.org/cgi-bin/QTLdb/index",
        "Reactome Download"              : "https://reactome.org/download/current/UniProt2Reactome_All_Levels.txt",
        "TreeFam Download"               : "http://www.treefam.org/download",
        "UniProt FTP"                    : "https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/",
        # Maize Community datasets:
        "MaizeGDB Expression download"   : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/MaizeGDB_qTeller_FPKM/B73v5_qTeller_FPKM",
        "Grotewold CAGE Tag Count Root download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_TSS",
        "Grotewold CAGE Tag Count Shoot download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_TSS",
        "GWAS Atlas download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_diversity_markers_and_GWAS/GWAS/SNPs_from_GWAS_Atlas_database",
        "MaizeGDB_UniformMu download" : "https://download.maizegdb.org/Insertions/UniformMu/",
        "Stam 2017 Husk H3K9ac Enhancer download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_epigenetics_and_DNA_binding/Oka_2017_enhancer_binding/Oka_Enhancer_Husk_v5.gff",
        "Stam 2017 Seedling H3K9ac Enhancer download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_epigenetics_and_DNA_binding/Oka_2017_enhancer_binding/Oka_Enhancer_Seedling_v5.gff",
        "Vollbrecht 2010 Ac/Ds Insertions download" : "https://download.maizegdb.org/Insertions/AcDs_Vollbrecht/",
        "Wallace 2014 GWAS download" : "https://datacommons.cyverse.org/browse/iplant/home/maizegdb/maizegdb/B73v5_JBROWSE_AND_ANALYSES/B73v5_diversity_markers_and_GWAS/GWAS/GWAS_SNPs_from_Wallace_2014/B73v5_Wallace_etal_2014_PLoSGenet_GWAS_hits-150112_blastn.gff.gz",
    }
    for linkText, url in linksWithinText.items():
        if (linkText in text):
            text = text.replace(linkText, createURL(linkText, url, True))
    for linkText, url in linksExactMatch.items():
        if (linkText == text):
            text = text.replace(linkText, createURL(linkText, url, True))
    # 3) convert NCBI FTP urls to links, if applicable:
    text = addFTPLinks(text)
    # 4) convert Ensembl Download urls to links, if applicable:
    if (len(text) > 23 and (text[0:23] == "https://ftp.ensembl.org")):
        text = createURL("Ensembl Download", text, True)
    if (len(text) > 22 and (text[0:22] == "http://ftp.ensembl.org")):
        text = createURL("Ensembl Download", text, True)
    if (len(text) > 26 and (text[0:26] == "https://useast.ensembl.org")):
        text = createURL("Ensembl Download", text, True)

    return text


def addFTPLinks(text):
    if (len(text) > 26 and (text[0:26] == "ftp://ftp.ncbi.nlm.nih.gov")):
        text = createURL("NCBI FTP", text, True)
    if (len(text) > 28 and (text[0:28] == "https://ftp.ncbi.nlm.nih.gov")):
        text = createURL("NCBI FTP", text, True)

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
            for colNum, col in enumerate(row):
                # Remove any line breaks from end of text
                col = col.rstrip('\n')
                
                # Initialize dictionary
                colVals = {}
                colVals['text'] = col
                colVals['spansRows'] = False
                colVals['rowSpan'] = 1
                colVals['spanStartRow'] = -1
                
                # Check if this column is part of a row span, and if so, update variables
                # Note that an asterisk (*) in front denotes keep separate row even if it matches the row above
                if ((rowNum > 0) and (col) and (col[0] != '*') and (col == tableRows[rowNum - 1][colNum]['text'])):
                    # Text in this column matches text from same column in previous row,
                    # so combine them into one colspan
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

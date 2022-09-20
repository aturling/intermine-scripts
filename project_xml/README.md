# Project.xml generator script

To run:

1. Create a subdirectory of the form ```<minename_lowercase>-v<version_number>```, e.g., ```maizemine-v1.5```, 
```hymenopteramine-v1.6```.

2. Add ```sources.sh``` to the subdirectory which specifies the functions from ```project_xml_functions.sh``` 
to call within ```add_mine_sources``` and their order to generate the ```project.xml``` file (different 
for each mine). Use ```examplemine-v1.0/sources.sh``` as an example.

3. Run ```generate_project_xml.sh```. The script uses the variables stored in ```~/.intermine/*.properties``` 
to get the mine name and version. (Note: this won't work if there are multiple ```*.properties``` files.)
The generated ```project.xml``` file is stored in ```<minename_lowercase>-v<version_number>/output/``` with 
the date and time appended to the filename

## Special cases for some sources

The script tries to automatically populate the ```project.xml``` fields whenever possible, but there are 
some exceptions where additional manual input is needed.

Some of the functions require parameters to indicate the source name, taxon id list, etc. Refer to the 
function usage in ```examplemine-v1.0/sources.sh```.

SNP sources use the file ```snp_sources.tab``` to get the Data Source name; this file has the format:

```
<Organism.name>	<DataSource.name>
```

Other sources use the file ```taxon_ids.tab``` to perform a lookup of the taxon id based on the Organism 
full name value. This file has the format:

```
<Organism.name>	<Organism.taxonId>
```

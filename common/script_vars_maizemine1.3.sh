#!/bin/bash 

# Variables common to intermine scripts

interminebasedir="/db/maizemine/MaizemineV1.3/intermine"
interminedir="${interminebasedir}/maizeminev1.3"
dbmodeldir="${interminedir}/dbmodel"
integratedir="${interminedir}/integrate"
integratelogfile="${integratedir}/intermine.log"
postprocessdir="${interminedir}/postprocess"
postprocesslogfile="${postprocessdir}/intermine.log"

uniprot_props_dir="${interminebasedir}/bio/sources/uniprot/main"
first_iteration_uniprot_props_file="${uniprot_props_dir}/main.resources.config/first_iteration_uniprot_config.properties"
second_iteration_uniprot_props_file="${uniprot_props_dir}/main.resources.config/second_iteration_uniprot_config.properties"
third_iteration_uniprot_props_file="${uniprot_props_dir}/main.resources.config/third_iteration_uniprot_config.properties"

uniprot_config_file="${uniprot_props_dir}/resources/uniprot_config.properties"

dbname="maizemine-version1.3"
dbuser=$(whoami) # default to current user running scripts
notifyemail="walshamy@missouri.edu"

#!/bin/bash 

# Variables common to intermine scripts

interminebasedir="/db/FAANGMine_release_v1.2/elsiklab-intermine/"
interminedir="${interminebasedir}/faangmine"
dbmodeldir="${interminedir}/dbmodel"
integratedir="${interminedir}/integrate"
integratelogfile="${integratedir}/intermine.log"
postprocessdir="${interminedir}/postprocess"
postprocesslogfile="${postprocessdir}/intermine.log"

first_iteration_uniprot_props_file="${interminebasedir}/bio/sources/uniprot/main/uniprot.main.resources.config/uniprot_config_first_iteration.properties"
second_iteration_uniprot_props_file="${interminebasedir}/bio/sources/uniprot/main/uniprot.main.resources.config/uniprot_config_second_iteration.properties"
uniprot_config_file="${interminebasedir}/bio/sources/uniprot/main/resources/uniprot_config.properties"

dbname="faangmine"
dbuser=$(whoami) # default to current user running scripts
notify_email=$MY_EMAIL

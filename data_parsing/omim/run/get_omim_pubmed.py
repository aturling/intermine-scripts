#!/usr/bin/env python3

"""
Script to fetch pubmed ids from mim number by using OMIM API

Original script here:
https://github.com/intermine/intermine-scripts/blob/master/bio/humanmine/get_omim_pubmed.py

Updated to parse returned JSON correctly and add more pauses to avoid hitting rate limit,
be compatible with Python v3, and process mim2gene.txt in chunks to allow restarting 
without losing progress.

Prerequisites:
(1) Python modules: Requests, Python-dotenv
(2) Split mim2gene into multiple files, each with the filename mim2gene_NN where NN is a
    two-digit number (with leading zero for 00-09), e.g.,
    $ split -d -l 1000 mim2gene.txt mim2gene_
    and store in current/ subdirectory.
(3) Copy .env_example to .env and add API key from omim.org.
(4) Edit idx_start and idx_end to match start and end suffix of split files (idx_start will
    initially be 0).

Output will be multiple pubmed_cited_NN files which can be combined into a single pubmed_cited.txt file.
"""
import os, json, requests, time, datetime, types
from dotenv import load_dotenv

# http://api.omim.org/api/html/apiKey.html
OMIM_SERVICE_BASE_USA = 'https://api.omim.org/api/entry'

# get API key from .env
load_dotenv()
apiKey = os.getenv('API_KEY')

class OMIMQueryError(Exception):
	pass

def get_omim_pubmed(mimNumber, log):
	log.write('Parsing MIM[' + mimNumber + ']\n')

	params = dict(
		mimNumber = mimNumber,
		apiKey = apiKey,
		format = 'json',
                include = 'referenceList'
	)

	resp = requests.get(url=OMIM_SERVICE_BASE_USA, params=params)
	data = resp.json() # In case the JSON decoding fails, r.json simply returns None.

	## parse pubmedId in JSON string
	pubmed_cited_list = list()
	ref_list = list()
	if type(data) is not None:
		entries = data['omim']['entryList']
		for entry in entries:
			if 'referenceList' in entry['entry']:
				pubmedID_count = 0
				ref_lists = entry['entry']['referenceList']
				for ref in ref_lists:
					try:
						pubmedID = ref['reference']['pubmedID']
						pubmedID_count += 1
						pubmed_cited_list.append(str(mimNumber) + '\t' + str(pubmedID_count) + '\t' + str(pubmedID))
					except KeyError as e:
						log.write('MIM[' + mimNumber + '] pubmedID does not exist: ' + str(ref['reference']) + '\n')

	else:
		log.write("Error parsing response:", resp);
	return pubmed_cited_list

def parse_mim_number(mim_number_file):
	mim_number_set = set() # mim in mim2gene are already unique, can replace set to list to main order, easy to validate by observation
	f = open(mim_number_file, 'r')

	for line in f:
		if not line.startswith('#') and line.split('\t').pop(1).find('phenotype'):
			mim_number_set.add(line.split('\t').pop(0))

	return mim_number_set

def timestamp_file(fname, fmt='%Y-%m-%d-%H-%M-%S_{fname}'):
	return datetime.datetime.now().strftime(fmt).format(fname=fname)

def process_mim_file(file_idx):
	LOG_DIR = '../logs/'
	LOG_NAME = 'pubmed_cited_' + file_idx + '.log'
	MIM_NUMBER_FILE = '../current/mim2gene_' + file_idx
	PUBMED_CITED_FILE = '../current/pubmed_cited_' + file_idx

	## get log file
	log = open(LOG_DIR + timestamp_file(LOG_NAME),'w+')

	print("Processing file: mim2gene_" + file_idx)
	log.write("Processing file: mim2gene_" + file_idx + "\n")
	log.write("Generating mim number set\n")
	log.flush()

	mim_number_set = set()
	## parse MIM number from mim2gene.txt file
	try:
		mim_number_set = parse_mim_number(MIM_NUMBER_FILE)
	except:
		print("Error while parsing mim2gene_" + file_idx)

	pubmed_cited_file = open(PUBMED_CITED_FILE,'w')

	log.write("Processing mim number set\n")
	log.flush()
	## send http requests to OMIM API (limit 4 requests/sec)		
	for mim_number in mim_number_set:
		time.sleep(5) # thread sleeps in sec

		try:
			pubmed_cited_list = get_omim_pubmed(mim_number, log)
			if pubmed_cited_list:
				# Only write to file if not empty
				pubmed_cited_file.write('\n'.join(pubmed_cited_list) + '\n')
		except OMIMQueryError as e:
			print("An API error occurred.")

	log.write('\nProcessing complete\n')
	log.close()
	pubmed_cited_file.close()

def main():
	# Start index is numerical suffix of first file (usually 0 unless restarting from a previous run)
	# End index is numerical suffix of last file, e.g. 27 if last file is mim2gene_27
	idx_start = 2
	idx_end = 2
	for idx in range(idx_start, idx_end+1):
		file_idx = str(idx)
		if (idx < 10):
			file_idx = "0" + file_idx
		process_mim_file(file_idx)
		time.sleep(300) # sleep 5 minutes before processing next file
		
if __name__ == "__main__":
	main()

# OMIM Publications

This script gets PubMed IDs for each mim number in mim2gene.txt via the omim.org API.

Original script here:
https://github.com/intermine/intermine-scripts/blob/master/bio/humanmine/get_omim_pubmed.py

Updated to parse returned JSON correctly and add more pauses to avoid hitting rate limit,
be compatible with Python 3, and process mim2gene.txt in chunks to allow restarting 
without losing progress.

To run:

1. Register for download and API access at https://www.omim.org and download all files
   including mim2gene.txt; place mim2gene.txt in the `current/` subdirectory.

2. Split mim2gene.txt into multiple files, each with the filename mim2gene_NN where NN is
   a two-digit number (with leading zero for 00-09), e.g.,

```
$ split -d -l 1000 mim2gene.txt mim2gene_
```

3. Install Python modules: Requests, Python-dotenv

4. Copy .env_example to .env and add omim.org API key.

```
# in run/ subdirectory:
$ cp .env_example .env
```

5. Edit the script to set `idx_start` and `idx_end` as the first index (initially 0) and last
   numerical suffix after running the `split` command.

6. Run script:

```
$ cd run/
$ ./get_omim_pubmed.py
```

Output will be multiple pubmed_cited_NN files (in `current/` subdirectory) which can be combined 
into a single pubmed_cited.txt file.

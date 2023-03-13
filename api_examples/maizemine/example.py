#!/usr/bin/env python3

import os
from dotenv import load_dotenv
from intermine.webservice import Service

MINE_URL = "https://maizemine.rnet.missouri.edu/maizemine"
SERVICE_URL = MINE_URL + "/service"

# get API key from .env
load_dotenv()
apiKey = os.getenv('API_KEY')


def run_simple_query(service):
    query = service.new_query("Gene")
    query.add_view("symbol", "source", "primaryIdentifier", "proteins.name")
    query.add_constraint("organism.name", "=", "Zea mays", code = "A")

    print('Running query:')
    print('<query model="genomic" view="Gene.symbol Gene.source Gene.primaryIdentifier Gene.proteins.name" sortOrder="Gene.symbol ASC">')
    print('  <constraint path="Gene.organism.name" op="=" value="Zea mays" code="A" />')
    print('</query>\n')
    print('First 10 results:')

    for row in query.rows(size=10):
        print(row["symbol"], row["source"], row["primaryIdentifier"], row["proteins.name"])


def main():
    service = Service(SERVICE_URL, token = apiKey)    

    # Example 1: Run a simple query
    run_simple_query(service)


if __name__ == "__main__":
	main()

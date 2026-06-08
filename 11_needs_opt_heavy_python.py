# Optimization needed: Processing millions of rows in Airflow memory (Pandas)
from airflow.decorators import task
import pandas as pd
from google.cloud import bigquery

@task
def process_data_in_memory():
    client = bigquery.Client()
    query = "SELECT * FROM DB_AEDWD2.massive_table"
    df = client.query(query).to_dataframe()
    
    # Very heavy local memory process
    df['new_col'] = df['amount'] * 1.2
    df.to_gbq('DB_AEDWD2.output_table', if_exists='replace')
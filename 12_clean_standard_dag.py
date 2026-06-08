# Clean: Standard BQ execution logic mapped correctly
from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from datetime import datetime

with DAG(
    dag_id='bq_transform_pipeline',
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1
) as dag:

    transform_data = BigQueryInsertJobOperator(
        task_id='transform_sales',
        configuration={
            "query": {
                "query": "{% include 'sql/transform.sql' %}",
                "useLegacySql": False,
            }
        }
    )
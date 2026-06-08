# Syntax Error: Missing indentation and unmatched parenthesis
from airflow import DAG
from datetime import datetime

with DAG('broken_dag', start_date=datetime(2026, 1, 1) as dag:
task_1 = DummyOperator(task_id='dummy'
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

default_args = {
    'owner': 'data_team',
    'start_date': datetime(2023, 1, 1),
    'catchup': True
}

DAG_NAME = 'customer_ingestion_pipeline'

dag = DAG(
    DAG_NAME,
    default_args=default_args,
    schedule_interval='@daily'
)

task1 = BashOperator(
    task_id='run_ksh',
    bash_command='sh /opt/scripts/run.ksh ',
    dag=dag
)

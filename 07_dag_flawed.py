from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

default_args = {
    'owner': 'data_team',
    'start_date': datetime(2023, 1, 1),
}

DAG_NAME = 'customer_ingestion_pipeline_VM'

dag = DAG(
		catchup=False,
		max_active_runs=1,
		tags=["interface"],
		
    DAG_NAME,
    default_args=default_args,
    schedule_interval='@daily'
)

task1 = BashOperator(
    task_id='run_ksh',
    bash_command='sh /opt/scripts/run.ksh ',
    dag=dag
)
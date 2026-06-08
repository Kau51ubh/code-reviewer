# Rule Violation: catchup=True, wrong name format, standard bash instead of gcloud ssh
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id='process_sales_data', # Missing _INTERFACE_VM
    start_date=datetime(2026, 1, 1),
    catchup=True, # Violation
) as dag:

    run_script = BashOperator(
        task_id='run_local_script',
        bash_command='sh /local/path/script.sh'
    )
# Clean: Proper naming, catchup=False, max_active_runs=1, uses gcloud ssh
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id='process_sales_INTERFACE_VM',
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
) as dag:

    run_vm_job = BashOperator(
        task_id='run_gcloud_ssh',
        bash_command='gcloud compute ssh data-user@sales-vm --command="python3 /opt/jobs/run.py"'
    )
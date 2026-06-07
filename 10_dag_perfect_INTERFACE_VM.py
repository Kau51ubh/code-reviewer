# SCENARIO: a fully compliant Airflow DAG (control / happy path).
# EXPECTED: no linter fixes. Status: CLEAN.
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

DAG_NAME = "ORDERS_INTERFACE_VM"

default_args = {
    "owner": "data_eng",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

dag = DAG(
    dag_id=DAG_NAME,
    default_args=default_args,
    schedule_interval="0 5 * * *",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["interface"],
)

run = BashOperator(task_id="run_load", bash_command="echo loading", dag=dag)

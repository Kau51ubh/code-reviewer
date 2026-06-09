# CLEAN: a fully compliant Airflow DAG (classic `dag = DAG(...)` form).
# _VM suffix on DAG_NAME, timedelta imported, catchup NOT in default_args, and
# catchup=False / max_active_runs=1 / tags set on the DAG. Compiles, single task.
# EXPECTED: Status CLEAN (no linter fixes, no AI).
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

DAG_NAME = "CUSTOMER_LOAD_INTERFACE_VM"

default_args = {
    "owner": "data_eng",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

dag = DAG(
    dag_id=DAG_NAME,
    default_args=default_args,
    schedule_interval="0 6 * * *",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["interface"],
)

run_customer_load = BashOperator(
    task_id="run_customer_load",
    bash_command="echo loading customers",
    dag=dag,
)

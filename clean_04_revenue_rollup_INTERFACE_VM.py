# CLEAN: a fully compliant Airflow DAG using the `with DAG(...) as dag:` context-manager
# form. _VM suffix, timedelta imported, catchup/max_active_runs/tags all present on the
# DAG. Compiles, single task. (Also confirms the linter leaves a compliant `with DAG(`
# file untouched — no phantom "injected max_active_runs" fix.)
# EXPECTED: Status CLEAN (no linter fixes, no AI).
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

DAG_NAME = "REVENUE_ROLLUP_INTERFACE_VM"

default_args = {
    "owner": "data_eng",
    "retries": 1,
    "retry_delay": timedelta(minutes=10),
}


def _rollup_revenue(**context):
    print("rolling up daily revenue")


with DAG(
    dag_id=DAG_NAME,
    default_args=default_args,
    schedule_interval="0 7 * * *",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["interface"],
) as dag:
    rollup_revenue = PythonOperator(
        task_id="rollup_revenue",
        python_callable=_rollup_revenue,
    )

# SCENARIO: Airflow DAG missing the _VM suffix, 'catchup' wrongly in default_args,
#           'timedelta' used but not imported, and DAG() missing required params.
# EXPECTED: linter appends _VM to DAG_NAME, injects the missing timedelta import,
#           removes catchup from default_args, and injects catchup=False,
#           max_active_runs=1, tags=["interface"] into DAG(). Status: AUTO-FIXED.
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

DAG_NAME = "ORDERS_INTERFACE"

default_args = {
    "owner": "data_eng",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "catchup": True,
}

dag = DAG(
    dag_id=DAG_NAME,
    default_args=default_args,
    schedule_interval="0 5 * * *",
    start_date=datetime(2024, 1, 1),
)

run = BashOperator(task_id="run_load", bash_command="echo loading", dag=dag)

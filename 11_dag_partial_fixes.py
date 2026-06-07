# SCENARIO: DAG that is partially compliant (name already _VM, catchup already
#           set) but still uses timedelta without importing it and is missing
#           max_active_runs and tags.
# EXPECTED: linter injects the timedelta import and injects max_active_runs=1 and
#           tags=["interface"] only (no duplicate catchup). Status: AUTO-FIXED.
from airflow import DAG
from datetime import datetime

DAG_NAME = "SALES_INTERFACE_VM"

default_args = {"owner": "data_eng", "retry_delay": timedelta(minutes=10)}

dag = DAG(
    dag_id=DAG_NAME,
    default_args=default_args,
    start_date=datetime(2024, 1, 1),
    catchup=False,
)

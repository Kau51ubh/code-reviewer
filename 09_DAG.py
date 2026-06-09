from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

TASKS = ["extract", "transform", "load"]

def process_task(task_name, **kwargs):
    print(f"Executing {task_name}...")
    # Add your logic here
    
default_args = {
    'owner': 'data_team',
    'depends_on_past': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='optimized_etl_pipeline',
    default_args=default_args,
    start_date=datetime(2026, 6, 1),
    schedule_interval='@daily',
    catchup=False,  # Optimization: Prevents backfilling if not needed
    tags=['production', 'optimized'],
) as dag:

    # 3. Optimization: Dynamic task generation
    # Avoids hardcoding repetitive tasks and keeps the DAG file lightweight
    prev_task = None
    for task_name in TASKS:
        current_task = PythonOperator(
            task_id=f"run_{task_name}",
            python_callable=process_task,
            op_kwargs={'task_name': task_name}
        )
        
        if prev_task:
            prev_task >> current_task
        prev_task = current_task

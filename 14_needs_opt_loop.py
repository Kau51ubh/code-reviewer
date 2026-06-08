# Optimization needed: Massive synchronous loops instead of dynamic task mapping or BQ offloading
from airflow.decorators import task
import time

@task
def loop_through_records():
    records = list(range(100000))
    for record in records:
        # Performing sequential I/O bound operations inside an Airflow worker
        time.sleep(0.01) 
        print(f"Processed {record}")
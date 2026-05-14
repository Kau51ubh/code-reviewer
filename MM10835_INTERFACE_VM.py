from airflow import DAG
from airflow.configuration import conf
from datetime import datetime
from airflow.models import Variable 
from airflow_common.operators.DART_SSH_Operator_ETL_VM import dart_custom_ssh_task 

DAG_NAME = "MM10835_INTERFACE"
COMPOSER_HOME="/home/airflow/gcs/"
SQL_DIR = COMPOSER_HOME + "dags/"
GLOBAL_CONF_DIR = COMPOSER_HOME + "dags/projectname-utils/config/"

default_args = {
	'depends_on_past': False,
	'email_on_failure': True,
	'email': Variable.get('smtp_mail_to'),
	'start_date': datetime(2021, 1, 24),
	'retries': 0,
	'catchup': True,
	'retry_delay': timedelta(minutes=0)
}

dag = DAG(dag_id=DAG_NAME,
		description="VM DAG",
		schedule_interval=None,
		default_args=default_args,
		template_searchpath=[SQL_DIR]
	)

MM10835_1 = dart_custom_ssh_task(
	task_id="MM10835_1",
	script_path="""
	ksh -x /load/{{var.value.GCP_ETL_VM_ENV}}/subjectarea/mm10835_wrapper.ksh 
""",
	dag=dag
)

MM10835_1
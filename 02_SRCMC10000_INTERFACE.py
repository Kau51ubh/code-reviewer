from airflow import DAG
from airflow.configuration import conf
from datetime import datetime,timedelta
from airflow.models import Variable
from airflow_common.operators.DART_SSH_Operator_ETL_VM import dart_custom_ssh_task

#-----------------------Global parameters-------------------------------------
DAG_NAME = "SRCMC10000_INTERFACE_VM"
COMPOSER_HOME = "/home/airflow/gcs/"
SQL_DIR = COMPOSER_HOME + "dags/"
GLOBAL_CONF_DIR = COMPOSER_HOME + "dags/ihg-dart-edw-common-utils/config/"

default_args = {
    'depends_on_past': False,
    'email_on_failure': True,
    'email': Variable.get('smtp_mail_to'),
    'start_date': datetime(2021, 1, 24),
    'retries': 0,
    'retry_delay': timedelta(minutes=0),
}

#-----------------------Dag Definition----------------------------------------
dag = DAG(dag_id=DAG_NAME,
          description='SRCMC10000_INTERFACE_VM',
          schedule_interval=None,
          default_args=default_args,
          template_searchpath=[SQL_DIR],
          )


#-----------------------Task Definition Starts---------------------------------

SRCMC10000_1 = dart_custom_ssh_task(
    task_id="SRCMC10000_1",
    script_path="""
ksh -x /home/{{ var.value.GCP_TL_VM_ENV }}/SA/FI/script/SRCMC10000_exec_interface.ksh SRCMC10435 N
""",
    dag=dag
)

SRCMC10000_1		  
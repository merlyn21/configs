from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago

from send2tg import send_failure
import pendulum
import datetime

default_args = {
    'owner': 'nasadulin',
    'start_date': datetime.datetime(2024, 9, 1),
    'depends_on_past': False,
}

with DAG(
    "get_data_vm_all", # Identifier, shown in the console
    default_args = default_args,
    description = "get_data_vm_all",
    schedule_interval='20 10,16,22 * * *', # Monthly execution
#    start_date = datetime(2024, 8, 1), # When to start the scheduled execution
    catchup=False,
    tags=["REGRU"],
    on_failure_callback=send_failure
) as dag1:

    t1 = BashOperator(
        task_id="get_data_vm_all", # Task identifier for tracking in the console
        bash_command="cd /opt/airflow/scripts/vmware && python3 get_data_vm_all.py",
        dag = dag1
    )

t1

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
    "service", # Identifier, shown in the console
    default_args = default_args,
    description = "service",
    schedule_interval='30 10 * * *', # Monthly execution
#    start_date = datetime(2024, 8, 1), # When to start the scheduled execution
    catchup=False,
    tags=["REGRU"],
    on_failure_callback=send_failure
) as dag1:

    t1 = BashOperator(
        task_id="service", # Task identifier for tracking in the console
        bash_command="cd /opt/airflow/scripts/tools && python3 service.py",
        dag = dag1
    )

t1

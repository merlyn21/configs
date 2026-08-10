from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago

from send2tg import send_failure
import pendulum
import datetime

default_args = {
    'owner': 'nasadulin',
    'start_date': datetime.datetime(2024, 8, 1),
    'depends_on_past': False,
}

with DAG(
    "alerter_veeam", # Identifier, shown in the console
    default_args = default_args,
    description = "Alerter veeam backups",
    schedule_interval='0 12 * * *',
#    start_date = datetime(2024, 8, 1), # When to start the scheduled execution
    catchup=False,
    tags=["REGRU"],
    on_failure_callback=send_failure
) as dag1:

    t1 = BashOperator(
        task_id="alerter_veeam", # Task identifier for tracking in the console
        bash_command="cd /opt/airflow/scripts/alerters && python3 alerter_veeam.py",
        dag = dag1
    )

t1

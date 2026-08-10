from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
from airflow.providers.telegram.operators.telegram import TelegramOperator

from send2tg import send_failure
import pendulum
import datetime

default_args = {
    'owner': 'nasadulin',
    'start_date': datetime.datetime(2024, 8, 1),
    'depends_on_past': False,
}

with DAG(
    "get_dns_regru", # Identifier, shown in the console
    default_args = default_args,
    description = "Get DNS grom regru",
    schedule_interval='35 10 * * *', # Monthly execution
#    start_date = datetime(2024, 8, 1), # When to start the scheduled execution
    catchup=False,
    tags=["REGRU"],
    on_failure_callback=send_failure
) as dag2:

    t2 = BashOperator(
        task_id="get_dns_regru_script", # Task identifier for tracking in the console
        bash_command="cd /opt/airflow/scripts/tools && python3 get_dns_regru.py",
        dag = dag2
    )

t2

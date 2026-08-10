from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago

from send2tg import send_failure
import pendulum
import datetime

default_args = {
    'owner': 'nasadulin',
    'start_date': datetime.datetime(2024, 9, 26),
    'depends_on_past': False,
}

with DAG(
    "billing_yandex", # Identifier, shown in the console
    default_args = default_args,
    description = "Billing YANDEX CLOUD",
    schedule_interval='40 10 * * *', # Monthly execution
#    start_date = datetime(2024, 8, 1), # When to start the scheduled execution
    catchup=False,
    tags=["YC"],
    on_failure_callback=send_failure
) as dag1:


#dag1 = DAG("billing_aws", start_date=days_ago(0, 0, 0, 0, 0))

    t1 = BashOperator(
        task_id="billing_yandex_script", # Task identifier for tracking in the console
        bash_command="cd /opt/airflow/scripts/alerters && python3 billing_yandex.py",
        dag = dag1
    )

t1

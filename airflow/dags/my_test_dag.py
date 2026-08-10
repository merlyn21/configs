import datetime
import pendulum

from airflow.models.dag import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator

from airflow.utils.dates import days_ago

dag1 = DAG("my_test_dag", start_date=days_ago(0, 0, 0, 0, 0))

operation = BashOperator(
    bash_command = "pwd",
    dag = dag1,
    task_id = 'operation_1'
)

operation

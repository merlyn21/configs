from airflow.providers.telegram.operators.telegram import TelegramOperator

def send_failure(context):
    send_message = TelegramOperator(
        task_id='send_message_to_telegram',
        telegram_conn_id='telega',
        text=f"\U0000274C DAG <b>{context['ti'].dag_id}</b>\n failed with an error in task {context['ti'].task_id}."
        )
    return send_message.execute(context=context)

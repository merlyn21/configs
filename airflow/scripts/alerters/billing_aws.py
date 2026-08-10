#Get billing information for two AWS accounts since the start of the current month

import boto3
from datetime import datetime, timedelta
import yaml

from send import send2channel

with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)

aws_key_id_2 = config['aws']['aws_access_key_id_2']
aws_secret_key_2 = config['aws']['aws_secret_access_key_2']
region_2 = config['aws']['region_name_2']

aws_key_id_7 = config['aws']['aws_access_key_id_7']
aws_secret_key_7 = config['aws']['aws_secret_access_key_7']
region_7 = config['aws']['region_name_7']

print(config)

client_2 = boto3.client(
    'ce',
    aws_access_key_id = aws_key_id_2,
    aws_secret_access_key = aws_secret_key_2,
    region_name = region_2  # e.g. 'us-east-1'
)

# Determine the current date and the start of the month
end_date = datetime.today().date()
start_date = end_date.replace(day=1)

# Request to get the total cost since the start of the month
response_2 = client_2.get_cost_and_usage(
    TimePeriod={
        'Start': start_date.isoformat(),
        'End': end_date.isoformat()
    },
    Granularity='MONTHLY',
    Metrics=['UnblendedCost']
)

# Get the cost total from the response
total_cost_2 = round(float(response_2['ResultsByTime'][0]['Total']['UnblendedCost']['Amount']), 2)
#print(total_cost_2)

client_7 = boto3.client(
    'ce',
    aws_access_key_id=aws_key_id_7,
    aws_secret_access_key=aws_secret_key_7,
    region_name=region_7
)

response_7 = client_7.get_cost_and_usage(
    TimePeriod={
        'Start': start_date.isoformat(),
        'End': end_date.isoformat()
    },
    Granularity='MONTHLY',
    Metrics=['UnblendedCost']
)

# Get the cost total from the response
total_cost_7 = round(float(response_7['ResultsByTime'][0]['Total']['UnblendedCost']['Amount']), 2)
#print(total_cost_7)

message_send = f"For the period from {start_date} to {end_date}, AWS costs: agrocorp = ${total_cost_7} AGRO1 = ${total_cost_2}\nTotal: ${round(total_cost_7 + total_cost_2, 2)}"

#print(message_send)
send2channel(message_send)

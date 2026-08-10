#Check the gitlab backup
#Send an alert to the Telegram channel based on the result

import boto3
from datetime import datetime
import yaml

from rec2db import insert_fields_backup
from send import send2channel

with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)

# Configure credentials and region
session = boto3.session.Session()
s3 = session.client(
    service_name = 's3',
    endpoint_url = config['yandex']['endpoint_url'],
    aws_access_key_id = config['yandex']['aws_key_id'],
    aws_secret_access_key = config['yandex']['aws_secret_key']
)

# Specify the bucket name
bucket_name = config['yandex']['bucket_name']

# Get the list of objects (files) in the bucket
response = s3.list_objects_v2(Bucket=bucket_name)

current_date = datetime.now()
current_date_str = datetime.now().strftime('%Y_%m_%d')
current_time = datetime.now()
print(current_date_str)

def extract_date_from_key(key):
    try:
        # Assumes the date is in 'YYYY_MM_DD' format and is the second part of the key, separated by an underscore
        parts = key.split('_')
        date_str = parts[1] + '_' + parts[2] + '_' + parts[3]  # '2024_03_01'
        return date_str
    except IndexError:
        return None

backup=0
# Check and print the list of objects
if 'Contents' in response:
    for obj in response['Contents']:
        key = obj['Key']
        # Check that the object is at the root (does not contain '/')
        if '/' not in key:
          key_date_str = extract_date_from_key(key)
          if key_date_str == current_date_str:
            backup = 1
            backup_name_f = key
            file_size = obj['Size']

    if backup == 1:
        print("OK. Backup file is found")
        print(f"{backup_name_f} : {file_size}")
        insert_fields_backup("gitlab", current_time, True, int(file_size), backup_name_f)
        send2channel("Gitlab backup file is found")
    else:
        print("Alarm! Backup file is not found!")
        send2channel("\U0000274C Alarm! Gitlab backup file is not found!")
        insert_fields_backup("gitlab", current_time, False, 0, "")

else:
    print('No files found in the root of the bucket.')

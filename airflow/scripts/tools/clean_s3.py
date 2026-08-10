import boto3
from datetime import datetime
import yaml

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

backup = []
count = 0
# Check and print the list of objects
if 'Contents' in response:
    for obj in response['Contents']:
        key = obj['Key']
        # Check that the object is at the root (does not contain '/')
        if '/' not in key and 'tar' in key:
#          print(key)
          count += 1
          key_date = datetime.strptime(extract_date_from_key(key), '%Y_%m_%d')
#          print(key_date)
          razn = current_date - key_date
#          print(f"Difference in days: {razn.days}")
          backup.append((key, razn.days))
else:
    print('No files found in the root of the bucket.')

print(count)
if count > 10:
    for data1 in backup:
        if data1[1] > 10 and data1[1] < 50:
            print(data1)
            resp = s3.delete_object(Bucket=bucket_name, Key=data1[0])
            print(f"Deleted {data1[0]} from {bucket_name}")

#print(backup)

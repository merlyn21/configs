#Check the criticalarcs table for empty metadata fields

import psycopg2
from string import Template
import time
import yaml

#import config
from get import get_count
from send import send2channel

with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)

dbname = config['db']['dbname']
user = config['db']['user']
password = config['db']['password']
host = config['db']['host']
port = config['db']['port']

metas = ['backup_name', 'description', 'path_location']

message_send = f"Warning! The critical archives table has unfilled metadata\n"

count_all = 0

for meta in metas:
    count = get_count(meta, '--', '--', 'criticalarcs')
#    print(count)
    if count:
        message_send += f"{meta} - {count} unfilled fields\n"
        count_all += 1

if count_all:
#    print(message_send)
    send2channel(message_send)

#if count_all:
#    message_send += f"Total unfilled metadata: {count_all} out of {count_vm*all_meta}\nNumber of VMs: {count_vm}\n"
#    print(message_send)
#    send2channel(message_send)



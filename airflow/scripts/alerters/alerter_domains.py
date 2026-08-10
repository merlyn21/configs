#Check domain registration expiration dates based on the dns table
import psycopg2
from datetime import datetime, timedelta
from string import Template
import time
import yaml

from send import send2channel

with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)

dbname = config['db']['dbname']
user = config['db']['user']
password = config['db']['password']
host = config['db']['host']
port = config['db']['port']

conn = psycopg2.connect(
    dbname=dbname,
    user=user,
    password=password,
    host=host,
    port=port
)

cur = conn.cursor()

query = "SELECT dns_name, type, datestamp from dns"
cur.execute(query)
rows = cur.fetchall()

cur.close()

curr_date = datetime.now()
diff_alert = 30

message_send = f"Warning! Certificate or domain expiration approaching\n"

for row in rows:
    diff = row[2] - curr_date
    if diff.days < diff_alert:
        message_send += f"{row[0]} {row[1]} - {row[2]} {diff.days}\n"
#        print(f"{row[0]} {row[1]} - {row[2]}  -- {diff}")


#    count = get_count(meta, '--', '--', 'services')
print(message_send)
#send2channel(message_send)




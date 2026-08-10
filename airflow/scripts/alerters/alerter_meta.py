#Check for empty metadata in the main virtual machines table

import psycopg2
from string import Template
import time
import yaml

from get import get_count
from send import send2channel

with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)

dbname = config['db']['dbname']
user = config['db']['user']
password = config['db']['password']
host = config['db']['host']
port = config['db']['port']
all_meta = 6

alerts_meta = {
    "description": ["", 0, ""],
    "customer": ["", 0, ""],
    "backupvm": ["", 0, ""],
    "backupdb": ["", 0, ""],
    "monitoring": ["", 0, ""],
    "sa-account": ["", 0, ""]
}

# Connect to the database
conn = psycopg2.connect(
    dbname=dbname,
    user=user,
    password=password,
    host=host,
    port=port
)


cur = conn.cursor()

query = "SELECT count(*) FROM vmware2"

cur.execute(query)
count_vm = cur.fetchone()[0]

query = "SELECT DISTINCT vdcname, provider FROM vmware2 ORDER BY provider"

#query = "SELECT size, datestamp FROM backup ORDER BY datestamp DESC LIMIT 1"
cur.execute(query)

# Fetch all rows from the query result
rows = cur.fetchall()


#message_tmpl = Template("vdcname: $vdcname, provider: $provider\nThere is unfilled metadata $meta - $count items\n")

message_tmpl = Template("$provider, vdcname: $vdcname  -  $count items\n")
#itogo_tmpl = Template("Total unfilled $itogo items")
message_send = 'There is unfilled metadata!\n'
count_all = 0

for row in rows:
    count_sum = 0
    for key, values in alerts_meta.items():
        count = get_count(key, row[0], row[1])
#        print(f"{key} {row[0]} {row[1]} {count}")
        if count > 0:
#            alerts_meta[key][0] += message_tmpl.substitute(vdcname=row[0], provider=row[1], count=count)
            count_sum += count
            count_all += count

    if count_sum > 0:
        message_send += message_tmpl.substitute(vdcname=row[0], provider=row[1], count=count_sum)

#print(message_send)

message_check = ""
count = get_count('check_backup', '--', '--')
if count < 10:
    message_check = f"Warning! Gitlab backup file size = {count}"



if count_all:
    message_send += f"Total unfilled metadata: {count_all} out of {count_vm*all_meta}\nNumber of VMs: {count_vm}\n"
#    print(message_send)
    send2channel(message_send)


# Close the cursor and connection
cur.close()
conn.close()


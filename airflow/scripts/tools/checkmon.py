#Check hosts for open port 9100 - running node_exporter
#The list of addresses to check is taken from the virtual machines table
#The check command runs on the monitoring data collection host
#For this, the run_on_rem function from remote_comm is called
#The address and port are passed
import psycopg2
from string import Template
import time
import yaml

import ipaddress

from remote_comm import run_on_rem

def is_valid_ip(address):
    try:
        ipaddress.ip_address(address)
        return True
    except ValueError:
        return False


with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)

dbname = config['db']['dbname']
user = config['db']['user']
password = config['db']['password']
host = config['db']['host']
port = config['db']['port']

table_name = 'vmware2'

conn = psycopg2.connect(
    dbname=dbname,
    user=user,
    password=password,
    host=host,
    port=port
)

cur = conn.cursor()

query = "select orgname, vdcname, vmname, ip_real, ip_local, status, ostype, provider from vmware2 where status=true"

#query = "SELECT size, datestamp FROM backup ORDER BY datestamp DESC LIMIT 1"
cur.execute(query)

# Fetch all rows from the query result
rows = cur.fetchall()

#cur.close()
#conn.close()

check = []

for row in rows:
    if is_valid_ip(row[3]) or is_valid_ip(row[4]):
        if 'win' in row[6]:
            if is_valid_ip(row[3]):
#                print(f"{row[7]} {row[3]} {row[4]} {row[6]}  win ---")
                res = run_on_rem(row[3], 9182)
                check.append((res, row[0], row[1], row[2]))
            elif is_valid_ip(row[4]):
#                print(f"{row[7]} {row[3]} {row[4]} {row[6]}  win")
                res = run_on_rem(row[4], 9182)
                check.append((res, row[0], row[1], row[2]))
        else:
            if is_valid_ip(row[3]):
#                print(f"{row[7]} {row[3]} {row[6]}  lin ---")
                res = run_on_rem(row[3], 9100)
                check.append((res, row[0], row[1], row[2]))
            elif is_valid_ip(row[4]):
#                print(f"{row[0]} {row[4]} {row[6]}  lin")
                res = run_on_rem(row[4], 9100)
                check.append((res, row[0], row[1], row[2]))



#record
print("start record to DB")

update_query = """
UPDATE vmware2 SET monitor_check = %s
WHERE orgname = %s and vdcname = %s and vmname = %s;
"""

for item in check:
    cur.execute(update_query, item)

conn.commit()

        # Close the cursor and connection
cur.close()
conn.close()

print("Data inserted successfully")

#for data in check:
#    print(data)


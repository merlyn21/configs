#Populate the services table based on the service field in the virtual machines table

import psycopg2
from string import Template
import time
import yaml

from rec2service import insert_fields

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

def split_string_by_all_commas(s):
    parts = s.split(',')
    return [part.strip() for part in parts]


cur = conn.cursor()

query = "SELECT DISTINCT service FROM vmware2 where service is not NULL and service != '' order by service"
select_services_tmpl = Template('''SELECT service, vdcname, vmname, orgname, provider, id, ip_real, ip_local  FROM vmware2 where service='$f' limit 1 ''')

#query = "SELECT size, datestamp FROM backup ORDER BY datestamp DESC LIMIT 1"
cur.execute(query)

# Fetch all rows from the query result
rows = cur.fetchall()

cur.close()
#conn.close()

services = []

for row in rows:
    curg = conn.cursor()
    query = select_services_tmpl.substitute(f=row[0])
    curg.execute(query)
    serv = curg.fetchall()
    curg.close()
    print(f"{serv[0][0]} {serv[0][6]} {serv[0][7]}")
#    vpn = ''
#    if serv[0][6] == '':
#        vpn = serv[0][7]

    if ',' in row[0]:
        all_parts = split_string_by_all_commas(row[0])
        for i, part in enumerate(all_parts):
#            print(f"{part} - {row[1]} - {row[3]}")
            services.append((part, serv[0][1], serv[0][2], serv[0][3], serv[0][4]))
    else:
#        print(f"{row[0]} - {row[1]} - {row[3]}")
        services.append((row[0], serv[0][1], serv[0][2], serv[0][3], serv[0][4]))


conn.close()

print("--")

for data in services:
    print(data)

print("start record to DB")
#insert_fields(services)

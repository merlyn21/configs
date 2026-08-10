#Get metadata information, called from alerter_meta

import psycopg2
from string import Template
import yaml

with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)

dbname = config['db']['dbname']
user = config['db']['user']
password = config['db']['password']
host = config['db']['host']
port = config['db']['port']

select_tmpl = Template('''SELECT count(*) FROM vmware2 where (TRIM("$f") = '' OR "$f" IS NULL) and vdcname='$vdcname' and provider='$provider' ''')

select_meta_tmpl = Template('''SELECT count(*) FROM $t where (TRIM("$f") = '' OR "$f" IS NULL) ''')
#select_services_tmpl = Template('''SELECT count(*) FROM services where (TRIM("$f") = '' OR "$f" IS NULL) ''')

def get_count(metadata, vdcname, provider, table="vmware2"):

    conng = psycopg2.connect(
        dbname=dbname,
        user=user,
        password=password,
        host=host,
        port=port
    )
    curg = conng.cursor()

    if metadata == 'description' or metadata == 'customer' or metadata == 'owner-tg':
        query = select_tmpl.substitute(f=metadata, vdcname=vdcname, provider=provider)
#        print(query)
#        query = "SELECT count(*) FROM vmware2 where (TRIM(description) = '' OR description IS NULL) and vdcname=%s and provider=%s"

#    if metadata == 'customer':
#        query = select_tmpl.substitute(f=metadata, vdcname=vdcname, provider=provider)
#        query = "SELECT count(*) FROM vmware2 where (TRIM(customer) = '' OR customer IS NULL) and vdcname=%s and provider=%s"

#    if metadata == 'owner-tg':
#        query = select_tmpl.substitute(f=metadata, vdcname=vdcname, provider=provider)
#        query = '''SELECT count(*) FROM vmware2 where (TRIM("owner-tg") = '' OR "owner-tg" IS NULL) and vdcname=%s and provider=%s'''

    if metadata == 'backupvm':
        query = "SELECT count(*) FROM vmware2 where (TRIM(backupvm) = '' OR backupvm IS NULL) and vdcname=%s and provider=%s"

    if metadata == 'backupdb':
        query = "SELECT count(*) FROM vmware2 where (TRIM(backupdb) = '' OR backupdb IS NULL) and vdcname=%s and provider=%s"

    if metadata == 'monitoring':
        query = "SELECT count(*) FROM vmware2 where (TRIM(monitoring) = '' OR monitoring IS NULL) and vdcname=%s and provider=%s"

    if metadata == 'efimov-account' or metadata == 'usmanov-account' or metadata == 'asadulin-account' \
       or metadata == 'golychev-account' or metadata == 'lisienkov-account' or metadata == 'sa-account':
        query = select_tmpl.substitute(f=metadata, vdcname=vdcname, provider=provider)


    if metadata == 'check_backup':
        query = "SELECT size, datestamp FROM backup ORDER BY datestamp DESC LIMIT 1"

    if table == 'criticalarcs':
        query = select_meta_tmpl.substitute(t=table, f=metadata)

    if table == 'services':
        query = select_meta_tmpl.substitute(t=table, f=metadata)

    if table == 'services_saas':
        query = select_meta_tmpl.substitute(t=table, f=metadata)

    param = (vdcname, provider)
    curg.execute(query, param)

    count = curg.fetchone()[0]

    curg.close()
    conng.close()
    return count

#a = get_count('description', 'class-dev-vdc', 'REGRU')

#print(f"Count: {a}")

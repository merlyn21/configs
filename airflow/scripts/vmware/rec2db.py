#Write VM information to the vmware2 database
#Called from the main get_data_vm_all function

import psycopg2
from psycopg2 import sql
from datetime import datetime
import yaml

with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)

dbname = config['db']['dbname']
user = config['db']['user']
password = config['db']['password']
host = config['db']['host']
port = config['db']['port']

table_name = 'vmware2'




def insert_fields(all_vms):
    try:
        # Connect to the database
        conn = psycopg2.connect(host=host, dbname=dbname, user=user, password=password, port=port)
        cur = conn.cursor()


#        for data in all_vms:
#          print(data)

#        if all_vms:
        current_ids = {(item[0], item[1], item[2]) for item in all_vms}
        formatted_ids = ','.join(cur.mogrify("(%s, %s, %s)", ids).decode('utf-8') for ids in current_ids)

        delete_query = sql.SQL(f"""
                                DELETE FROM {table_name}
                                WHERE (orgname, vdcname, vmname) NOT IN ({formatted_ids})
                               """)
        cur.execute(delete_query)

        for item in all_vms:
            upsert_query = sql.SQL("""
            INSERT INTO {table} (orgname, vdcname, vmname, num_cpus, memory_mb, ip_real, ip_local,
                                   status, datestamp, ostype, created, vapp, provider)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (orgname, vdcname, vmname)
            DO UPDATE SET
            num_cpus = EXCLUDED.num_cpus,
            memory_mb = EXCLUDED.memory_mb,
            ip_real = EXCLUDED.ip_real,
            ip_local = EXCLUDED.ip_local,
            status = EXCLUDED.status,
            datestamp = EXCLUDED.datestamp,
            ostype = EXCLUDED.ostype,
            created = EXCLUDED.created,
            vapp = EXCLUDED.vapp,
            provider = EXCLUDED.provider
            """).format(table=sql.Identifier(table_name))
    
        for item in all_vms:
#            print(item)
            cur.execute(upsert_query, item)

        conn.commit()

        # Close the cursor and connection
        cur.close()
        conn.close()

        print("Data inserted successfully")

    except (Exception, psycopg2.DatabaseError) as error:
        print(f"Error: {error}")
    finally:
        if conn is not None:
            conn.close()


#current_time = datetime.now()
#insert_fields("test_orgname", "test_vdcname", "test_vmname", "11.22.33.44", True, 4, 8192, "", current_time)

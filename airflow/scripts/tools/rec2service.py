#Function to write to the services table
#Called from service.py
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

def insert_fields(svc):
    table_name = 'services'
    try:
        # Connect to the database
        conn = psycopg2.connect(host=host, dbname=dbname, user=user, password=password, port=port)
        cur = conn.cursor()


#        for data in all_vms:
#          print(data)

#        if all_vms:
        current_ids = {(item[0], item[1], item[2]) for item in svc}
        formatted_ids = ','.join(cur.mogrify("(%s, %s, %s)", ids).decode('utf-8') for ids in current_ids)

        delete_query = sql.SQL(f"""
                                DELETE FROM {table_name}
                                WHERE (name, vdcname, vmname) NOT IN ({formatted_ids})
                               """)
        cur.execute(delete_query)

        for item in svc:
            print(item)
            upsert_query = sql.SQL("""
            INSERT INTO {table} (name, vdcname, vmname, orgname, provider)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (name, vdcname, vmname)
            DO UPDATE SET
            orgname = EXCLUDED.orgname,
            provider = EXCLUDED.provider
            """).format(table=sql.Identifier(table_name))

        for item in svc:
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

#Functions to write to the psql table for 

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

db_params = {
    'dbname': dbname,
    'user': user,
    'password': password,
    'host': host,
    'port': port
}


def insert_fields_backup(service_name, datestamp, succesfull, size, file_name):
    try:
        # Connect to the database
        conn = psycopg2.connect(**db_params)
        cur = conn.cursor()

        # SQL query to insert data 14
        insert_query = sql.SQL("""
            INSERT INTO backup (service_name, datestamp, succesfull, size, file_name)
            VALUES (%s, %s, %s, %s, %s)
        """)

        cur.execute(insert_query, (service_name, datestamp, succesfull, size, file_name))

        # Commit changes
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


def insert_fields_dns(all_dns):
    try:
        # Connect to the database
        table_name = 'dns'
        conn = psycopg2.connect(host=host, dbname=dbname, user=user, password=password, port=port)
        cur = conn.cursor()

        current_ids = {(item[0], item[1]) for item in all_dns}
        formatted_ids = ','.join(cur.mogrify("(%s, %s)", ids).decode('utf-8') for ids in current_ids)

        delete_query = sql.SQL(f"""
                                DELETE FROM {table_name}
                                WHERE (dns_name, type) NOT IN ({formatted_ids})
                               """)
        cur.execute(delete_query)

        for item in all_dns:
            upsert_query = sql.SQL("""
            INSERT INTO {table} (dns_name, type, datestamp)
            VALUES (%s, %s, %s)
            ON CONFLICT (dns_name, type)
            DO UPDATE SET
            datestamp = EXCLUDED.datestamp
            """).format(table=sql.Identifier(table_name))
    
        for item in all_dns:
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


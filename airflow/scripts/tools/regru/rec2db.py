import psycopg2
from psycopg2 import sql
from datetime import datetime

import config

dbname = config.dbname
user = config.user
password = config.password
host = config.host
port = config.port
table_name = 'dns'

def insert_fields(all_dns):
    try:
        # Connect to the database
        conn = psycopg2.connect(host=host, dbname=dbname, user=user, password=password, port=port)
        cur = conn.cursor()


#        for data in all_vms:
#          print(data)

#        if all_vms:
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


#current_time = datetime.now()
#insert_fields("test_orgname", "test_vdcname", "test_vmname", "11.22.33.44", True, 4, 8192, "", current_time)

import psycopg2
from psycopg2 import sql
from datetime import datetime

db_params = {
    'dbname': 'dbname',
    'user': 'user',
    'password': 'pass',
    'host': 'localhost',
    'port': '5432'
}


def insert_fields(orgname, vdcname, vmname, ip_real, status, num_cpus, memory_mb, ip_local, datestamp, description, ostype):
    try:
        # Подключение к базе данных
        conn = psycopg2.connect(**db_params)
        cur = conn.cursor()

        upsert_query = """
            INSERT INTO vms (orgname, vdcname, vmname, ip_real, status, num_cpus, memory_mb, ip_local, datestamp, description, ostype)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (orgname, vdcname, vmname)
            DO UPDATE SET
                ip_real = EXCLUDED.ip_real,
                status = EXCLUDED.status,
                num_cpus = EXCLUDED.num_cpus,
                memory_mb= EXCLUDED.memory_mb,
                ip_local = EXCLUDED.ip_local,
                datestamp = EXCLUDED.datestamp,
                description = EXCLUDED.description,
                ostype = EXCLUDED.ostype;

        """

#        print(f"Inserting: {orgname}, {vdcname}, {vmname}, {ip_real}, {status}, {num_cpus}, {memory_mb}, {ip_local}, {datestamp}, {description}, {ostype}")
#        print(upsert_query)
        # Выполнение запроса
        cur.execute(upsert_query, (orgname, vdcname, vmname, ip_real, status, num_cpus, memory_mb, ip_local, datestamp, description, ostype))

        # Фиксация изменений
        conn.commit()

        # Закрытие курсора и соединения
        cur.close()
        conn.close()

        print("Data inserted successfully")

    except (Exception, psycopg2.DatabaseError) as error:
        print(f"Error: {error}")
    finally:
        if conn is not None:
            conn.close()

import psycopg2
from psycopg2 import sql
import nmap

# Settings for connecting to the PostgreSQL database
db_host = 'localhost'
db_name = 'vmware'
db_user = 'postgres'
db_password = ''
db_port = '5432'

source_table_name = 'ip_addresses'
results_table_name = 'open_ports'

# Function to scan ports
def scan_ports(ip):
    nm = nmap.PortScanner()
    nm.scan(ip, arguments='--top-ports=100 -Pn')
    #nm = nmap.scan_top_ports()
    #nm.scan(ip)
    open_ports = []
    for proto in nm[ip].all_protocols():
        lport = nm[ip][proto].keys()
        for port in lport:
            if nm[ip][proto][port]['state'] == 'open':
                open_ports.append(port)
    return open_ports

# Connect to the database
conn = psycopg2.connect(host=db_host, dbname=db_name, user=db_user, password=db_password, port=db_port)
cur = conn.cursor()

# Read IP addresses from the source_ips table
cur.execute(sql.SQL("SELECT ip FROM {}").format(sql.Identifier(source_table_name)))
rows = cur.fetchall()
ips = [row[0] for row in rows]

# Scan ports and save results to the open_ports table
cur.execute(sql.SQL("CREATE TABLE IF NOT EXISTS {} (ip TEXT, open_ports TEXT)").format(sql.Identifier(results_table_name)))
cur.execute(sql.SQL("DELETE FROM {}").format(sql.Identifier(results_table_name)))

for ip in ips:
    open_ports = scan_ports(ip)
    open_ports_str = ','.join(map(str, open_ports))
    cur.execute(sql.SQL("INSERT INTO {} (ip, open_ports) VALUES (%s, %s)").format(sql.Identifier(results_table_name)), [ip, open_ports_str])

conn.commit()
cur.close()
conn.close()

# Print the scan results
for ip in ips:
    open_ports = scan_ports(ip)
    print(f"Open ports for {ip}: {open_ports}")


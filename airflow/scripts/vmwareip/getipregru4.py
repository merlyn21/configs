import re
import psycopg2
from psycopg2 import sql
import ipaddress
from lxml import etree
from pyvcloud.vcd.client import BasicLoginCredentials, Client
from pyvcloud.vcd.vdc import VDC
from pyvcloud.vcd.org import Org
from pyvcloud.vcd.gateway import Gateway

# Configuration
host = 'cloud-nimbuscorp.vmcloud.reg.ru'
username = 'n.asadulin'
password = ''
org_name = 'nimbuscorp'
vdc_name = 'nimbuscorp-infrastructure'
api_version = '37.0'  # Version of the Cloud Director API you want to use

# Settings for connecting to the PostgreSQL database
db_host = 'localhost'
db_name = 'vmware'
db_user = 'postgres'
db_password = ''
db_port = '5432'
table_name = 'ip_addresses'

# Create the client and authenticate
client = Client(host, api_version, verify_ssl_certs=True)
client.set_credentials(BasicLoginCredentials(username, org_name, password))

# Get the organization
org_resource = client.get_org()
org = Org(client, resource=org_resource)

# Get the VDC
vdc_resource = org.get_vdc(vdc_name)
vdc = VDC(client, resource=vdc_resource)

# Get the list of all edge gateways
edge_gateways = vdc.list_edge_gateways()

# Function to check public IP addresses
def is_public_ip(ip):
    try:
        ip_obj = ipaddress.ip_address(ip)
        return ip_obj.is_global
    except ValueError:
        return False

# Function to process IP addresses, ranges, and networks
def extract_ips(ip):
    ips = []
    try:
        if isinstance(ip, str):
            ip = ip.strip()
            # Check for a range
            if '-' in ip:
                start_ip, end_ip = ip.split('-')
                start_ip = ipaddress.ip_address(start_ip.strip())
                end_ip = ipaddress.ip_address(end_ip.strip())
                current_ip = start_ip
                while current_ip <= end_ip:
                    if is_public_ip(current_ip):
                        ips.append(str(current_ip))
                    current_ip += 1
            # Check for a network
            elif '/' in ip:
                network = ipaddress.ip_network(ip.strip(), strict=False)
                for ip_addr in network:
                    if is_public_ip(ip_addr):
                        ips.append(str(ip_addr))
            # Check for a single IP
            elif is_public_ip(ip):
                ips.append(ip)
    except ValueError:
        pass
    return ips

# Collect IP addresses from all edge gateways
used_ips = []
for edge_gateway in edge_gateways:
    gateway = Gateway(client, href=edge_gateway.get('href'))
    gateway_name = edge_gateway.get('name')
    print(f"Processing Edge Gateway: {gateway_name}")
    gateway_resource = gateway.get_resource()
    
    if hasattr(gateway_resource, 'Configuration'):
        print(f"Configuration found for {gateway_name}")
        if hasattr(gateway_resource.Configuration, 'GatewayInterfaces'):
            print(f"GatewayInterfaces found for {gateway_name}")
            for interface in gateway_resource.Configuration.GatewayInterfaces.GatewayInterface:
                if hasattr(interface, 'SubnetParticipation'):
                    for subnet in interface.SubnetParticipation:
                        if hasattr(subnet, 'IpAddress'):
                            ip_address = subnet.IpAddress
                            if is_public_ip(ip_address):
                                print(f"Found public IP: {ip_address}")
                                used_ips.append(ip_address)
                        if hasattr(subnet, 'IpRanges'):
                            for ip_range in subnet.IpRanges.IpRange:
                                start_address = ip_range.StartAddress
                                end_address = ip_range.EndAddress
                                ips = extract_ips(f"{start_address}-{end_address}")
                                used_ips.extend(ips)
                                for ip in ips:
                                    print(f"Found IP in range: {ip}")
        else:
            print(f"No GatewayInterfaces found for {gateway_name}")
    else:
        print(f"No Configuration found for {gateway_name}")

# Close the connection
client.logout()

# Remove duplicate IP addresses
used_ips = list(set(used_ips))

# Filter to keep only numeric public IP addresses
filtered_ips = [ip for ip in used_ips if re.match(r'^\d{1,3}(\.\d{1,3}){3}$', ip) and is_public_ip(ip)]

# Insert IP addresses into the PostgreSQL table
conn = psycopg2.connect(host=db_host, dbname=db_name, user=db_user, password=db_password, port=db_port)
cur = conn.cursor()

cur.execute(sql.SQL("CREATE TABLE IF NOT EXISTS {} (ip TEXT PRIMARY KEY)").format(sql.Identifier(table_name)))

# Remove records not present in filtered_ips
filtered_ips_tuple = tuple(filtered_ips)  # Convert the list to a tuple
delete_query = sql.SQL("DELETE FROM {} WHERE ip NOT IN ({})").format(
    sql.Identifier(table_name),
    sql.SQL(',').join(sql.Placeholder() * len(filtered_ips_tuple))
)
cur.execute(delete_query, filtered_ips_tuple)

for ip in filtered_ips:
    cur.execute(sql.SQL("INSERT INTO {} (ip) VALUES (%s) ON CONFLICT (ip) DO NOTHING").format(sql.Identifier(table_name)), [ip])

conn.commit()
cur.close()
conn.close()

# Print the list of IP addresses
for ip in filtered_ips:
    print(ip)


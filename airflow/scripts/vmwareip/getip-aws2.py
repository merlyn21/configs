import boto3
import re
import psycopg2
from psycopg2 import sql
import ipaddress

# Configuration
provider = 'AWS'
profile_name = 'agro1'  # Specify the desired AWS profile here
db_host = 'localhost'
db_name = 'vmware'
db_user = 'postgres'
db_password = ''
db_port = '5432'
table_name = 'ip_addresses'
default_region = 'us-east-1'  # Specify the default region

# Function to check public IP addresses
def is_public_ip(ip):
    try:
        ip_obj = ipaddress.ip_address(ip)
        return ip_obj.is_global
    except ValueError:
        return False

# Get the list of all AWS regions
def get_aws_regions(session):
    ec2 = session.client('ec2', region_name=default_region)
    response = ec2.describe_regions()
    regions = [region['RegionName'] for region in response['Regions']]
    return regions

# Connect to the PostgreSQL database
conn = psycopg2.connect(host=db_host, dbname=db_name, user=db_user, password=db_password, port=db_port)
cur = conn.cursor()

cur.execute(sql.SQL("CREATE TABLE IF NOT EXISTS {} (provider TEXT, org_name TEXT, vdc_name TEXT, ip TEXT PRIMARY KEY)").format(sql.Identifier(table_name)))

all_filtered_ips = []

# Create a boto3 session for the specified profile
session = boto3.Session(profile_name=profile_name)

aws_regions = get_aws_regions(session)
for region in aws_regions:
    print(f"Processing region: {region}")

    ec2 = session.client('ec2', region_name=region)

    # Extract IP addresses from EC2 instances
    response = ec2.describe_instances()
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            if 'PublicIpAddress' in instance:
                ip_address = instance['PublicIpAddress']
                if is_public_ip(ip_address):
                    print(f"Found public IP: {ip_address}")
                    all_filtered_ips.append((provider, profile_name, region, ip_address))

    # Extract IP addresses from network interfaces (ENI)
    response = ec2.describe_network_interfaces()
    for interface in response['NetworkInterfaces']:
        if 'Association' in interface and 'PublicIp' in interface['Association']:
            ip_address = interface['Association']['PublicIp']
            if is_public_ip(ip_address):
                print(f"Found public IP: {ip_address}")
                all_filtered_ips.append((provider, profile_name, region, ip_address))

# Remove records not present in all_filtered_ips
if all_filtered_ips:
    delete_query = sql.SQL("DELETE FROM {} WHERE provider = 'AWS' AND org_name = 'agro1' AND ip NOT IN ({})").format(
        sql.Identifier(table_name),
        sql.SQL(',').join(sql.Placeholder() * len(all_filtered_ips))
    )
    cur.execute(delete_query, [ip[3] for ip in all_filtered_ips])

for ip_data in all_filtered_ips:
    cur.execute(sql.SQL("INSERT INTO {} (provider, org_name, vdc_name, ip) VALUES (%s, %s, %s, %s) ON CONFLICT (ip) DO NOTHING").format(sql.Identifier(table_name)), ip_data)

# Commit and close the database connection
conn.commit()
cur.close()
conn.close()

# Print the list of IP addresses
for ip_data in all_filtered_ips:
    print(ip_data[3])

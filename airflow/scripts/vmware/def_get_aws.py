#Get VM information from AWS accounts

import boto3
import re
import psycopg2
from psycopg2 import sql
import ipaddress
from datetime import datetime

#import yaml

# Configuration
provider = 'AWS'
#profile_name = 'agro2'  # Specify the desired AWS profile here
default_region = 'us-east-1'  # Specify the default region

# Get the list of all AWS regions
def get_aws_regions(session):
    ec2 = session.client('ec2', region_name=default_region)
    response = ec2.describe_regions()
    regions = [region['RegionName'] for region in response['Regions']]
    return regions

datestamp = datetime.now()

#all_vms = []

# Create a boto3 session for the specified profile

def get_vm_aws(all_vms1, aws_access_key_id, aws_secret_access_key, region_name, profile_name):

    session = boto3.Session(
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        region_name=region_name
    )

#    session = boto3.Session(profile_name=profile_name)

    aws_regions = get_aws_regions(session)
    for region in aws_regions:
#    print(f"Processing region: {region}")

        ec2 = session.client('ec2', region_name=region)

    # Extract IP addresses from EC2 instances
        response = ec2.describe_instances()

        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                name_tag = None
                if 'Tags' in instance:
                  for tag in instance['Tags']:
                    if tag['Key'] == 'Name':
                        name_tag = tag['Value']
                        break

                orgname = profile_name
                vdcname = region
                vmname = name_tag
                num_cpus = 0
                memory_mb = 0
                ip_real = instance.get('PublicIpAddress')
                ip_local = instance.get('PrivateIpAddress')
                ostype = instance['InstanceType']
                created = instance['LaunchTime']
                vapp = instance['InstanceId']
                if instance['State']['Name'] == "running":
                    status = True
                else:
                    status = False

                all_vms1.append((orgname, vdcname, vmname, num_cpus, memory_mb, ip_real, ip_local,
                                 status, datestamp, ostype, created, vapp, provider))

    return all_vms1


#with open('../config.yml', 'r') as file:
#    config = yaml.safe_load(file)

#aws_key_id_2 = config['aws']['aws_access_key_id_2']
#aws_secret_key_2 = config['aws']['aws_secret_access_key_2']
#region_2 = config['aws']['region_name_2']

#aws_key_id_7 = config['aws']['aws_access_key_id_7']
#aws_secret_key_7 = config['aws']['aws_secret_access_key_7']
#region_7 = config['aws']['region_name_7']


#all_vms = []

#all_vms = get_vm_aws(all_vms, aws_key_id_2, aws_secret_key_2, region_2, 'agro1')
#all_vms = get_vm_aws(all_vms, aws_key_id_7, aws_secret_key_7, region_7, 'agro2')

#for data in all_vms:
#    print(data)

#Calls the data collection functions for different providers in turn
#Writes the collected information to the vmware2 table

import ipaddress
from datetime import datetime

from rec2db import insert_fields
from def_get_aws import get_vm_aws
from def_get_vmware import get_vm_vmware
from def_get_selectel import get_vm_selectel
from def_get_selectel_2 import get_vm_selectel2
from def_get_proxmox import get_vm_proxmox
import yaml

with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)

all_vms = []

host = config['regru']['host']
username = config['regru']['username']
password = config['regru']['password']
org = config['regru']['org']
provider = config['regru']['provider']
org_name = config['regru']['org_name']
vdc_name = config['regru']['vdc_name']

all_vms = get_vm_vmware(host, username, password, org, org_name, vdc_name, provider, all_vms)
print("ok regru")

host = config['dataline']['host']
username = config['dataline']['username']
password = config['dataline']['password']
org = config['dataline']['org']
provider = config['dataline']['provider']
org_name = config['dataline']['org_name']
vdc_name = config['dataline']['vdc_name']

all_vms = get_vm_vmware(host, username, password, org, org_name, vdc_name, provider, all_vms)
print("ok dataline")

host = config['dataline2']['host']
username = config['dataline2']['username']
password = config['dataline2']['password']
org = config['dataline2']['org']
provider = config['dataline2']['provider']
org_name = config['dataline2']['org_name']
vdc_name = config['dataline2']['vdc_name']

#all_vms = get_vm_vmware(host, username, password, org, org_name, vdc_name, provider, all_vms)
#print("ok dataline2")

aws_key_id_2 = config['aws']['aws_access_key_id_2']
aws_secret_key_2 = config['aws']['aws_secret_access_key_2']
region_2 = config['aws']['region_name_2']

aws_key_id_7 = config['aws']['aws_access_key_id_7']
aws_secret_key_7 = config['aws']['aws_secret_access_key_7']
region_7 = config['aws']['region_name_7']

all_vms = get_vm_aws(all_vms, aws_key_id_2, aws_secret_key_2, region_2, 'agro1')
all_vms = get_vm_aws(all_vms, aws_key_id_7, aws_secret_key_7, region_7, 'agro2')
print("ok AWS")

all_vms = get_vm_selectel('TEST','ru-2', 'SELECTEL', all_vms)
all_vms = get_vm_selectel('TEST','ru-7', 'SELECTEL', all_vms)
all_vms = get_vm_selectel('TEST','uz-1', 'SELECTEL', all_vms)
all_vms = get_vm_selectel('PROD','ru-1', 'SELECTEL', all_vms)
all_vms = get_vm_selectel('PROD','ru-7', 'SELECTEL', all_vms)
all_vms = get_vm_selectel('PROD','kz-1', 'SELECTEL', all_vms)
print("ok SELECTEL")

all_vms = get_vm_selectel2('locotech','ru-2', 'SELECTEL2', all_vms)
all_vms = get_vm_selectel2('clover','ru-2', 'SELECTEL2', all_vms)
print("ok SELECTEL2")

all_vms = get_vm_proxmox('PROXMOX', all_vms)
print("ok PROXMOX")

#for data in all_vms:
#    print(data)

print("start record to DB")
insert_fields(all_vms)

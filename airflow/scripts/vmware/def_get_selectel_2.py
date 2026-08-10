#Get VM information from SELECTEL accounts

import openstack
import ipaddress
from datetime import datetime
import yaml

with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)

auth_url = config['selectel2']['auth_url']
username = config['selectel2']['username']
password = config['selectel2']['password']
user_domain_name = config['selectel2']['user_domain_name']
project_domain_name = config['selectel2']['project_domain_name']

def is_private_ip(address):
    return any([
        ipaddress.ip_address(address).is_private,
        ipaddress.ip_address(address) in ipaddress.ip_network('172.16.0.0/12'), 
    ])


def get_vm_selectel2(orgname, region, provider, all_vms1):

# Configure connection parameters
    conn = openstack.connection.Connection(
        auth_url=auth_url,
        project_name=orgname,
        username=username,
        password=password,
        region_name=region,
        user_domain_name=user_domain_name,
        project_domain_name=project_domain_name
    )

    vdcname = region
    datestamp = datetime.now()
    vapp = ''
    ostype = ''

    ip_local = ''
    ip_real = ''

# Get the list of servers
    servers = conn.compute.servers()
    for server in servers:

        if server.status == 'ACTIVE':
            status = True
        else:
            status = False

        vmname = server.name
        num_cpus = server.flavor.vcpus
        memory_mb = server.flavor.ram
        created = server.created_at

        ip_local = ''
        ip_real = ''

        addresses = server.addresses
        for network_name, network_info in addresses.items():
            for address_info in network_info:
                ip_type = address_info.get('OS-EXT-IPS:type')
                ip_address = address_info.get('addr')
                if is_private_ip(ip_address):
                    ip_local = ip_address
                else:
                   ip_real = ip_address

#        print(f"{server.name};{status};{server.flavor.vcpus};{server.flavor.ram};{server.created_at};{ip_real};{ip_local}")

        all_vms1.append((orgname, vdcname, vmname, num_cpus, memory_mb, ip_real, ip_local,
                         status, datestamp, ostype, created, vapp, provider))

    return all_vms1


#all_vms = []

#all_vms = get_vm_selectel2('locotech','ru-2', 'SELECTEL2', all_vms)
#all_vms = get_vm_vmware('ru-7', 'SELECTEL', all_vms)

#for data in all_vms:
#    print(data)

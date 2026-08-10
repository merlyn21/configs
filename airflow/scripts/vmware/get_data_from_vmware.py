from pyvcloud.vcd.client import BasicLoginCredentials
from pyvcloud.vcd.client import Client
from pyvcloud.vcd.org import Org
from pyvcloud.vcd.vdc import VDC
from pyvcloud.vcd.vapp import VApp
from pyvcloud.vcd.vm import VM
import ipaddress
from datetime import datetime

from rec2db import insert_fields
from def_get_aws import get_vm_aws


def is_private_ip(address):
    return any([
        ipaddress.ip_address(address).is_private,
        ipaddress.ip_address(address) in ipaddress.ip_network('172.16.0.0/12'), # Additional check for 172.16.0.0/12
    ])
# Check whether the string is a valid IP address
def is_valid_ip(address):
    try:
        ipaddress.ip_address(address)
        return True
    except ValueError:
        return False


#----------------------------REGRU------------------------------------------
# Specify connection parameters
host = 'cloud-nimbuscorp.vmcloud.reg.ru'
username = 'n.asadulin'
password = ''
#username = 'n_asadulin_api'
#password = '11'


cpus = 0
mems = 0

#org = 'nimbuscorp'
org = 'system'
api_version = '37.0'  # Version of the Cloud Director API you want to use
provider = 'REGRU'

# Create the client object
client = Client(host, api_version, verify_ssl_certs=True)

datestamp = datetime.now()

# Authenticate
client.set_credentials(BasicLoginCredentials(username, org, password))

orgs = client.get_org_list()
#print(orgs)

all_vms = []


for org in orgs:
    orgObject = Org(client, href=org.attrib["href"])
    orgname = org.attrib["name"]
#    print(orgName)
    for vdc_info in orgObject.list_vdcs():
        vdcname = vdc_info['name']
        vdcHref = vdc_info['href']
        vdc = VDC(client, href=vdcHref)
        for resource in vdc.list_resources():
            if resource["type"] == "application/vnd.vmware.vcloud.vApp+xml":
#                print(resource)
                currentVappHref = vdc.get_vapp(resource["name"])
                currentVapp = VApp(client, resource=currentVappHref)
                vms = currentVapp.get_all_vms()
                for vm in vms:
                    vmname = vm.get('name')
                    if vm.get('status') == '4':
                      status = True
                    else: status = False
                    vm_resource = currentVapp.get_vm(vm.get('name'))
                   
                    if hasattr(vm_resource.VmSpecSection, 'NumCpus'):
                      num_cpus = int(vm_resource.VmSpecSection.NumCpus)
                    if hasattr(vm_resource.VmSpecSection, 'MemoryResourceMb'):
                      memory_mb = int(vm_resource.VmSpecSection.MemoryResourceMb.Configured)

                    description = str(getattr(vm_resource, 'Description', None)) + " "
                    ostype = "Unknown"
                    backupvm = "unnecessary"
                    backupdb = "unnecessary"
                    customer = ""
                    creds = ""
                    monitoring = "No"

                    if hasattr(vm_resource.VmSpecSection, 'OsType'):
                      guest_os_orig = vm_resource.VmSpecSection.OsType
                      ostype = str(guest_os_orig.text.replace("64Guest", "").replace("_", ""))

                      created = str(getattr(vm, 'DateCreated'))
                      vmm = VM(client, resource=vm_resource)

                      metadata = vmm.get_metadata()
                      metadata_dict = {}

                      if hasattr(metadata, 'MetadataEntry'):
                        for entry in metadata.MetadataEntry:
                          key = entry.Key
                          value = entry.TypedValue.Value
                          metadata_dict[key] = value

                      for key, value in metadata_dict.items():
#                      print(key)
#                      print(str(value))
                        if key == 'Описание':
                          description += value
                        if key == 'Veeam Backup':
#                          if str(value) == "True":
                          backupvm = str(value)
                        if key == 'customer' or key == 'Customer':
                          customer = str(value)
                        if key == 'DB Backup':
                          backupdb = value
                        if key == 'creds':
                          creds = str(value)
                        if key == 'monitoring' and str(value) != "":
                          monitoring = str(value)

                    vapp = currentVappHref.get('name')

                    vm_xml = client.get_resource(vm_resource.get('href'))
                    namespaces = {'vcloud': 'http://www.vmware.com/vcloud/v1.5'}

                    ip_addresses = vm_xml.xpath('//vcloud:IpAddress', namespaces=namespaces)
                    ip_real = ""
                    ip_local = ""

                    if ip_addresses:
                      valid_ip_addresses = [ip.text for ip in ip_addresses if is_valid_ip(ip.text) and not is_private_ip(ip.text)]
                      if valid_ip_addresses:
                        for ip_address_str in valid_ip_addresses:
                          ip_real  = ip_address_str
                      else:
                        v_address_str = [ip.text for ip in ip_addresses]
                        for ip_address_str in v_address_str:
                          ip_local = ip_address_str


#insert_fields("test_orgname", "test_vdcname", "test_vmname", "11.22.33.44", True, 4, 8192, "", current_time)


#                    print(f"{orgName=};{vdcName=};{vmName=};{num_cpus};{memory_mb};{vmStatus};{ip_addr};{ip_addr_l};{description};{guest_os};{backupvm};{backupdb};{creds};{created};{customer}")
                    all_vms.append((orgname, vdcname, vmname, num_cpus, memory_mb, ip_real, ip_local,
                                   status, datestamp, ostype, created, vapp, provider))


#                    all_vms.append((orgname, vdcname, vmname, num_cpus, memory_mb, ip_real, ip_local,
#                                   status, datestamp, description, ostype, customer, backupvm, backupdb,
#                                   creds, created, monitoring, vapp))

#                    cpus+=num_cpus
#                    mems+=memory_mb

#for data in all_vms:
#  print(data)
#print(cpus)
#print(mems)

client.logout()

#----------------------------------DATALINE-------------------------
# Configuration
host = 'dcloud.ru'
username = 'admin_nimbus'
password = ''
provider = 'DATALINE'
org = 'nimbus'
org_name = 'nimbus'
vdc_name = 'nimbus-OST4'
api_version = '37.0' 

cpus = 0
mems = 0

# Create the client object
client = Client(host, api_version, verify_ssl_certs=True)

# Authenticate
client.set_credentials(BasicLoginCredentials(username, org, password))

orgs = client.get_org_list()

for org in orgs:
    orgObject = Org(client, href=org.attrib["href"])
    orgname = org.attrib["name"]
    for vdc_info in orgObject.list_vdcs():
        vdcname = vdc_info['name']
        vdcHref = vdc_info['href']
        vdc = VDC(client, href=vdcHref)
        for resource in vdc.list_resources():
            if resource["type"] == "application/vnd.vmware.vcloud.vApp+xml":
                currentVappHref = vdc.get_vapp(resource["name"])
                currentVapp = VApp(client, resource=currentVappHref)
                vms = currentVapp.get_all_vms()
                for vm in vms:
                    vmname = vm.get('name')
                    if vm.get('status') == '4':
                      status = True
                    else: status = False
                    vm_resource = currentVapp.get_vm(vm.get('name'))
                    if hasattr(vm_resource.VmSpecSection, 'NumCpus'):
                      num_cpus = int(vm_resource.VmSpecSection.NumCpus)
                    if hasattr(vm_resource.VmSpecSection, 'MemoryResourceMb'):
                      memory_mb = int(vm_resource.VmSpecSection.MemoryResourceMb.Configured)

                    description = str(getattr(vm_resource, 'Description', None)) + " "
                    ostype = "Unknown"
                    backupvm = "unnecessary"
                    backupdb = "unnecessary"
                    customer = ""
                    creds = ""
                    monitoring = "No"

                    if hasattr(vm_resource.VmSpecSection, 'OsType'):
                      guest_os_orig = vm_resource.VmSpecSection.OsType
                      ostype = str(guest_os_orig.text.replace("64Guest", "").replace("_", ""))

                      created = str(getattr(vm, 'DateCreated'))
                      vmm = VM(client, resource=vm_resource)

                      metadata = vmm.get_metadata()
                      metadata_dict = {}

                      if hasattr(metadata, 'MetadataEntry'):
                        for entry in metadata.MetadataEntry:
                          key = entry.Key
                          value = entry.TypedValue.Value
                          metadata_dict[key] = value

                      for key, value in metadata_dict.items():
#                      print(key)
#                      print(str(value))
                        if key == 'Описание':
                          description += value
                        if key == 'Veeam Backup':
#                          if str(value) == "True":
                          backupvm = str(value)
                        if key == 'customer' or key == 'Customer':
                          customer = str(value)
                        if key == 'DB Backup':
                          backupdb = value
                        if key == 'creds':
                          creds = str(value)
                        if key == 'monitoring' and str(value) != "":
                          monitoring = str(value)

                    vapp = currentVappHref.get('name')

                    vm_xml = client.get_resource(vm_resource.get('href'))
                    namespaces = {'vcloud': 'http://www.vmware.com/vcloud/v1.5'}

                    ip_addresses = vm_xml.xpath('//vcloud:IpAddress', namespaces=namespaces)
                    ip_real = ""
                    ip_local = ""

                    if ip_addresses:
                      valid_ip_addresses = [ip.text for ip in ip_addresses if is_valid_ip(ip.text) and not is_private_ip(ip.text)]
                      if valid_ip_addresses:
                        for ip_address_str in valid_ip_addresses:
                          ip_real  = ip_address_str
                      else:
                        v_address_str = [ip.text for ip in ip_addresses]
                        for ip_address_str in v_address_str:
                          ip_local = ip_address_str

#                    print(f"{orgname};{vdcname};{vmname};{num_cpus};{memory_mb};{ip_real};{ip_local};{status};{datestamp};{ostype};{created};{vapp}")
                    all_vms.append((orgname, vdcname, vmname, num_cpus, memory_mb, ip_real, ip_local,
                                   status, datestamp, ostype, created, vapp, provider))


#                    cpus+=num_cpus
#                    mems+=memory_mb

client.logout()

all_vms = get_vm_aws(all_vms, 'agro1')
all_vms = get_vm_aws(all_vms, 'agro2')


#for data in all_vms:
#    print(data)


print("start record to DB")
insert_fields(all_vms)

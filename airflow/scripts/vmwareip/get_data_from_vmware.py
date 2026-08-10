from pyvcloud.vcd.client import BasicLoginCredentials
from pyvcloud.vcd.client import Client
from pyvcloud.vcd.org import Org
from pyvcloud.vcd.vdc import VDC
from pyvcloud.vcd.vapp import VApp
from pyvcloud.vcd.vm import VM
import ipaddress
from datetime import datetime

from rec2db import insert_fields

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

# Create the client object
client = Client(host, api_version, verify_ssl_certs=True)

current_time = datetime.now()
# Authenticate
client.set_credentials(BasicLoginCredentials(username, org, password))

orgs = client.get_org_list()
#print(orgs)

for org in orgs:
    orgObject = Org(client, href=org.attrib["href"])
    orgName = org.attrib["name"]
#    print(orgName)
    for vdc_info in orgObject.list_vdcs():
        vdcName = vdc_info['name']
        vdcHref = vdc_info['href']
        vdc = VDC(client, href=vdcHref)
        for resource in vdc.list_resources():
            if resource["type"] == "application/vnd.vmware.vcloud.vApp+xml":
#                print(resource)
                currentVappHref = vdc.get_vapp(resource["name"])
                currentVapp = VApp(client, resource=currentVappHref)
                vms = currentVapp.get_all_vms()
                for vm in vms:
                    vmName = vm.get('name')
                    if vm.get('status') == '4':
                      vmStatus = True
                    else: vmStatus = False
                    vm_resource = currentVapp.get_vm(vm.get('name'))
                    num_cpus = int(vm_resource.VmSpecSection.NumCpus)
                    memory_mb = int(vm_resource.VmSpecSection.MemoryResourceMb.Configured)

                    description = str(getattr(vm_resource, 'Description', None)) + " "
                    guest_os_orig = vm_resource.VmSpecSection.OsType
                    guest_os = str(guest_os_orig.text.replace("64Guest", "").replace("_", ""))

                    vmm = VM(client, resource=vm_resource)

                    metadata = vmm.get_metadata()
                    metadata_dict = {}
                    backup = "False"

                    if hasattr(metadata, 'MetadataEntry'):
                      for entry in metadata.MetadataEntry:
                        key = entry.Key
                        value = entry.TypedValue.Value
                        metadata_dict[key] = value

                    for key, value in metadata_dict.items():
#                      print(key)
                      if key == 'Описание':
                        description += value
                      if key == 'Veeam Backup':
                        if str(value) == "True":
                          backup = "True"

                    vm_xml = client.get_resource(vm_resource.get('href'))
                    namespaces = {'vcloud': 'http://www.vmware.com/vcloud/v1.5'}

                    ip_addresses = vm_xml.xpath('//vcloud:IpAddress', namespaces=namespaces)
                    ip_addr = ""
                    ip_addr_l = ""

                    if ip_addresses:
                      valid_ip_addresses = [ip.text for ip in ip_addresses if is_valid_ip(ip.text) and not is_private_ip(ip.text)]
                      if valid_ip_addresses:
                        for ip_address_str in valid_ip_addresses:
                           ip_addr = ip_address_str
                      else:
                        v_address_str = [ip.text for ip in ip_addresses]
                        for ip_address_str in v_address_str:
                          ip_addr_l = ip_address_str


#insert_fields("test_orgname", "test_vdcname", "test_vmname", "11.22.33.44", True, 4, 8192, "", current_time)


                    print(f"{orgName=};{vdcName=};{vmName=};{num_cpus};{memory_mb};{vmStatus};{ip_addr};{ip_addr_l};{description};{guest_os};{backup}")
                    insert_fields(orgName, vdcName, vmName, ip_addr, vmStatus, num_cpus, memory_mb, ip_addr_l, current_time, description, guest_os)

                    cpus+=num_cpus
                    mems+=memory_mb


print(cpus)
print(mems)


client.logout()

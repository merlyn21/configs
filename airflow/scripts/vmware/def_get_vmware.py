#Get VM information from VMWARE accounts

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

api_version = '37.0'
datestamp = datetime.now()

def is_private_ip(address):
    return any([
        ipaddress.ip_address(address).is_private,
        ipaddress.ip_address(address) in ipaddress.ip_network('172.16.0.0/12'),
    ])
# Check whether the string is a valid IP address
def is_valid_ip(address):
    try:
        ipaddress.ip_address(address)
        return True
    except ValueError:
        return False


def get_vm_vmware(host, username, password, org, org_name, vdc_name, provider, all_vms1):

# Create the client object
    client = Client(host, api_version, verify_ssl_certs=True)

# Authenticate
    client.set_credentials(BasicLoginCredentials(username, org, password))

    orgs = client.get_org_list()
#print(orgs)

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
#                          else:
                          v_address_str = [ip.text for ip in ip_addresses]
                          for ip_address_str in v_address_str:
                            if is_private_ip(ip_address_str):
                              ip_local = ip_address_str

#                        print(f"{orgname};{vdcname};{vmname};{num_cpus};{memory_mb};{ip_real};{ip_local};{status};{datestamp};{ostype};{created};{vapp};{provider}")
                        all_vms1.append((orgname, vdcname, vmname, num_cpus, memory_mb, ip_real, ip_local,
                                        status, datestamp, ostype, created, vapp, provider))

    return all_vms1
    client.logout()


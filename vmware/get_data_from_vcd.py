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
        ipaddress.ip_address(address) in ipaddress.ip_network('172.16.0.0/12'), # Дополнительная проверка для 172.16.0.0/12
    ])
# Проверяем, является ли строка действительным IP-адресом
def is_valid_ip(address):
    try:
        ipaddress.ip_address(address)
        return True
    except ValueError:
        return False



# Указываем параметры для подключения
host = 'vmware.cloud.director'
username = 'user'
password = 'pass'


cpus = 0
mems = 0

#org = 'ctrl2go'
org = 'system'
api_version = '37.0'  # Версия API Cloud Director, которую вы хотите использовать

# Создаем объект клиента
client = Client(host, api_version, verify_ssl_certs=True)

current_time = datetime.now()
# Авторизуемся
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

                    description = str(getattr(vm_resource, 'Description', None))
                    guest_os_orig = vm_resource.VmSpecSection.OsType
                    guest_os = str(guest_os_orig.text.replace("64Guest", "").replace("_", ""))


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


                    print(f"{orgName=} {vdcName=} {vmName=}, num_cpus={num_cpus}, memory_mb={memory_mb}, status={vmStatus}, ip={ip_addr}, ipl={ip_addr_l}, {description}, {guest_os}")
                    insert_fields(orgName, vdcName, vmName, ip_addr, vmStatus, num_cpus, memory_mb, ip_addr_l, current_time, description, guest_os)

                    cpus+=num_cpus
                    mems+=memory_mb


print(cpus)
print(mems)


client.logout()

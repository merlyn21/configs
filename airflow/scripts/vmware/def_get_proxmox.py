#Get VM information from proxmox accounts

from proxmoxer import ProxmoxAPI
from datetime import datetime
import yaml

with open('../config.yml', 'r') as file:
    config = yaml.safe_load(file)

ip = config['proxmox']['ip']
user = config['proxmox']['user']
password = config['proxmox']['password']

proxmox = ProxmoxAPI(ip, user=user, password=password, verify_ssl=False, service='PVE')

#all_vms = []
datestamp = datetime.now()


def get_vm_proxmox(provider, all_vms1):

    orgname = 'nimbus-office'

    for node in proxmox.nodes.get():
       vdcname = node['node']
#       print(vdcname)
       if node['status'] == 'online':
#      for vm in proxmox.nodes(node['node']).lxc.get():
#         if vm['status'] == 'stopped':
#            print(vm['vmid'], vm['name'], vm['status'])
#         else:
#            print(vm['vmid'], vm['name'], vm['status'], "pid=" + vm['pid'])
#         print(proxmox.nodes(node['node']).lxc(vm['vmid']).config().get())
          for vm in proxmox.nodes(node['node']).qemu.get():
#              if vm['status'] == 'stopped':
#                  print(vm['vmid'], vm['name'], vm['status'], vm['cpus'], vm['mem'])
#              else:
#                  print(vm['vmid'], vm['name'], vm['status'], vm['cpus'], vm['mem'], "pid=" + vm['pid'])
              config = proxmox.nodes(node['node']).qemu(vm['vmid']).config().get()

#proxmox.nodes('pve').qemu(vmid).agent('network-get-interfaces').get()
              
              print(config)
#              print(f"{config['name']} {config['cores']*config['sockets']} {config['memory']} {config['ostype']}")

              vmname = config['name']
              num_cpus = config['cores']*config['sockets']
              memory_mb = config['memory']
              ip_real = ""
              ip_local = ""
              ostype = config['ostype']
              created = ""
              vapp = ""
              if vm['status'] == 'stopped':
                  status = False
              else:
                  status = True

              all_vms1.append((orgname, vdcname, vmname, num_cpus, memory_mb, ip_real, ip_local,
                                status, datestamp, ostype, created, vapp, provider))

    return all_vms1

all_vms = []
get_vm_proxmox('prox', all_vms)
#for data in all_vms:
#    print(data)

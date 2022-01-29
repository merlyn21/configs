wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-1+ubuntu20.04_all.deb
dpkg -i zabbix-release_6.0-1+ubuntu20.04_all.deb
apt update
apt install zabbix-agent2


openssl rand -hex 32 > zabbix_agent2.psk

#TLSConnect=psk
#TLSAccept=psk
#TLSPSKFile=/etc/zabbix/zabbix_agent2.psk
#TLSPSKIdentity=PSK 001


usermod -aG docker zabbix
setfacl --modify user:zabbix:rw /var/run/docker.sock

zabbix-agent2
=============

Installs Zabbix Agent 2 (v6.5) from the official Zabbix repo and wires it up
for PSK-encrypted communication with the Zabbix server: generates a random
32-byte PSK (`/etc/zabbix/zabbix_agent2.psk`), enables `TLSConnect=psk` /
`TLSAccept=psk`, and points the agent at `zb_server` with the host's
`inventory_hostname` as both the TLS PSK identity and the reported hostname.

Requirements
------------

A Debian/Ubuntu-family host (the package URL is built from
`ansible_distribution` / `ansible_distribution_version`).

Role Variables
--------------

| Variable | Default | Description |
|---|---|---|
| `zb_server` | `zabbix.example.com` | Address of the Zabbix server/proxy the agent reports to. |

Note: after this role runs, the generated PSK lives only on the target host
at `/etc/zabbix/zabbix_agent2.psk` — it must be registered against the same
host in the Zabbix frontend (Configuration → Hosts → Encryption) for the
server to accept the connection.

Example Playbook
----------------

    - hosts: all
      become: yes
      roles:
        - { role: zabbix-agent2, when: ansible_system == 'Linux' }
      vars:
        zb_server: zabbix.example.com

License
-------

MIT-0

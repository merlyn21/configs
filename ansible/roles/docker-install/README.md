docker-install
==============

Installs Docker Engine on a target Linux host using the official
`get.docker.com` convenience script, and drops a `daemon.json` that caps
container log files (`max-size: 100m`, `max-file: 5`) to avoid unbounded
disk growth from `json-file` logs.

Requirements
------------

None beyond a supported Linux distribution reachable over SSH with a
privilege-escalation-capable user.

Role Variables
--------------

None — the role is intentionally parameter-free.

Example Playbook
----------------

    - hosts: all
      become: yes
      roles:
        - { role: docker-install, when: ansible_system == 'Linux' }

License
-------

MIT-0

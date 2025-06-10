# Infrastruture

Stores 
    - Ansible playbooks and roles for configuring, hardening, and maintaining your servers.
    - Automated Ubuntu installation script

# File Structure
```
infrastructure/
├── ubuntu-autoinstall/
│   ├── autoinstall-configs/
│   │   ├── user-data.yaml (RAID-6 config)
│   │   └── meta-data
│   ├── scripts/
│   │   └── generate-iso.sh
│   └── docs/
│       └── RAID6_setup.md
├── inventory/
│   ├── production
│   └── staging
├── group_vars/
│   ├── all.yml
│   └── vault.yml (encrypted)
├── roles/
│   ├── common/
│   ├── security/
│   ├── teleport/
│   ├── wazuh/
│   ├── elk_stack/
│   └── vault/
├── playbooks/
│   ├── bootstrap.yml
│   ├── hardening.yml
│   ├── monitoring.yml
│   ├── vault.yml
│   └── patching.yml
└── .github/
    └── workflows/
        └── ansible-ci.yml

```

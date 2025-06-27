# Infrastructure

Stores 
    - Ansible playbooks and roles for configuring, hardening, and maintaining your servers.
    - Automated Ubuntu installation script

# File Structure
```
infrastructure/
├── inventory
│   ├── production
│   └── staging
├── playbooks
│   ├── bootstrap.yml
│   └── site.yml
├── roles
│   ├── common
│   ├── elk_stack
│   ├── security
│   ├── teleport
│   ├── vault
│   └── wazuh
├── ub-autoinstall
├── ansible.cfg
└── README.md
```


以下内容废弃，忽略.
---

## 子模块的使用和维护
使用 `git clone --recursive https://github.com/inteclab/infrastructure.git` 克隆本项目及子模块

## 子模块的修改和更新
```bash
cd ubuntu-autoinstall
git checkout -b feature-x
# 开发...
git push origin feature-x

# 2. 定期同步（比如每月）
# 在 GitHub 上点击 "Sync fork"
# 如果有冲突，GitHub 会提示
# 解决冲突后再同步到项目
# 回到主目录
git submodule update --remote

# 3. 提交父项目中的子模块引用变更
git add .                                   
git commit -m "Update submodule to latest"
git push
```
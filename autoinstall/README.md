项目介绍
=======
* 脚本根据配置生成用于自动安装的 ubuntu server ISO文件.
* 参考项目地址：https://github.com/YasuhiroABE/ub-autoinstall-iso
* 克隆日期：2025-6-17
* 更新时间：2025-6-25


使用方法
====================

安装依赖包.

    $ sudo apt update
    $ sudo apt install git make sudo

要下载ISO映像并填充初始文件（以下任务仅执行一次）.

    $ make download
    $ make init

每次生成都需要执行：

**使用官方的原版引导结构：**
    $ make geniso


生成ISO时，可能因为locale设置而失败, 可以通过指定 LANG=C.

在Makefile文件中修改 `GENISO_LANG` 值.

config/user-data file
---------------------

**配置文件自动选择机制：**

系统会自动按优先级选择配置文件：
1. 优先使用 `config/user-data`（如果存在）
2. 自动回退到 `config/user-data.efi`（UEFI系统，创建ESP分区）
3. 最后回退到 `config/user-data.mbr`（BIOS系统，使用MBR分区表）

**使用场景：**
* `config/user-data.efi` - 现代服务器，支持UEFI引导
* `config/user-data.mbr` - 老旧硬件，仅支持传统BIOS引导

另外还支持GRUB，参照原文档.

------------------------------



默认用户密码
---------------------

根据需要更改 `user-data` 中的 `username`和`password`.


* ID: acap
* Password: secret
* （注意，即使不使用密码，仍然需要配置Password，否则会出错）

生成对应 `secret`字符的hash.

    $ openssl passwd -6 -salt "$(openssl rand -hex 8)" secret

其他设置
==============

sudoers文件被安排用于 Ansible
-------------------------------------------------

这包括一个 `sudoers` 文件，该文件已被设置为用户 `acap` 不需要密码.

如果您想更改此设置，请编辑 `config/extras/acap.sudoers` .

SSH keys
--------

下面是一个为默认用户 `acap` 提供 ssh 密钥的例子.

    ssh:
      authorized-keys:
        - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAIH8mvfUPhRddvGXBxGcvwo5m3CRVOf8RbFXwaUa9mhLX comment"
        - "..."




History
=======
* 2025/06/25（经过修改后核心部分相当于全部重写，仅使用了原项目架构）
  * 使用官方原版引导参数封装，支持BIOS与UEFI引导。
  * 优化 user-data.efi
  * 删除其他无用的 生成ISO命令，只保留官方的方式
  * 删除isolinux

* 2025/06/24 (下午更新)
  * 实现配置文件智能选择逻辑，支持 .efi/.mbr 自动回退
  * 简化命令结构，删除冗余目标，保留核心功能
  * 将 geniso-original 重命名为 geniso，作为推荐方式
  * 优化 Makefile，减少25%代码量，提高可维护性

* 2025/06/24 (上午更新)
  * 新增官方原始引导结构支持，解决实体服务器引导兼容性问题
  * 新增 setup-minimal 目标，仅添加autoinstall配置而不修改官方引导文件
  * 改进帮助信息，明确区分不同ISO生成方式的适用场景

* 2025/06/19
  * 增加了官方sha256的校验
  * 增加了一些其他的辅助方法如设置代理等


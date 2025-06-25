SHELL := /bin/bash
ISO_URLBASE = https://releases.ubuntu.com/24.04/
ISO_FILENAME = ubuntu-24.04.2-live-server-amd64.iso
ISO_MOUNTPOINT = /mnt/iso
ISO_ROOT = iso_root

# SHA256 校验和缓存文件
ISO_SHA256_CACHE = .$(ISO_FILENAME).sha256
ISO_SHA256_URL = $(ISO_URLBASE)/SHA256SUMS

# 代理配置文件
PROXY_CONFIG = .proxy_config

## copy files
USERDATA_SRC = config/user-data
USERDATA_DEST = iso_root/user-data
METADATA_SRC = config/meta-data
METADATA_DEST = iso_root/meta-data
EXTRAS_SRCDIR = config/extras/
EXTRAS_DESTDIR = iso_root/

# ISO 生成参数
GENISO_FILENAME = ubuntu-custom-autoinstaller.$(shell date +%Y%m%d.%H%M%S).iso
GENISO_VOLID = Ubuntu-Server 24.04.2 LTS amd64
GENISO_MODIFICATION_DATE = $(shell date +%Y%m%d%H%M%S00)
GENISO_LANG = C

# 代理设置
.PHONY: set-proxy
set-proxy:
	@if [ -z "$(PROXY)" ]; then \
		echo "用法: make set-proxy PROXY=<代理地址>"; \
		echo "示例:"; \
		echo "  make set-proxy PROXY=http://127.0.0.1:7890"; \
		echo "  make set-proxy PROXY=socks5://127.0.0.1:1080"; \
		exit 1; \
	fi
	@echo "设置代理: $(PROXY)"
	@echo "export http_proxy=$(PROXY)" > $(PROXY_CONFIG)
	@echo "export https_proxy=$(PROXY)" >> $(PROXY_CONFIG)
	@echo "export HTTP_PROXY=$(PROXY)" >> $(PROXY_CONFIG)
	@echo "export HTTPS_PROXY=$(PROXY)" >> $(PROXY_CONFIG)
	@echo "export ftp_proxy=$(PROXY)" >> $(PROXY_CONFIG)
	@echo "export FTP_PROXY=$(PROXY)" >> $(PROXY_CONFIG)
	@echo "export no_proxy=localhost,127.0.0.1,::1" >> $(PROXY_CONFIG)
	@echo "export NO_PROXY=localhost,127.0.0.1,::1" >> $(PROXY_CONFIG)
	@echo "✓ 代理配置已保存到 $(PROXY_CONFIG)"

# 取消代理
.PHONY: unset-proxy
unset-proxy:
	@echo "取消代理设置..."
	@rm -f $(PROXY_CONFIG)
	@echo "✓ 代理配置文件已删除"

# 显示代理状态
.PHONY: proxy-status
proxy-status:
	@echo "=== 代理状态 ==="
	@if [ -f "$(PROXY_CONFIG)" ]; then \
		echo "代理配置文件: 存在"; \
		echo "配置内容:"; \
		cat $(PROXY_CONFIG); \
	else \
		echo "代理配置文件: 不存在"; \
	fi
	@echo ""
	@echo "当前环境变量:"
	@echo "http_proxy: $${http_proxy:-未设置}"
	@echo "https_proxy: $${https_proxy:-未设置}"

# 使用代理执行命令的辅助函数
define with_proxy
	$(if $(wildcard $(PROXY_CONFIG)), source $(PROXY_CONFIG) && )
endef

# 获取官方 SHA256 值（支持代理）
.PHONY: get-official-sha256
get-official-sha256:
	@if [ ! -f "$(ISO_SHA256_CACHE)" ]; then \
		echo "获取官方 SHA256 校验和 ($(ISO_SHA256_URL))..."; \
		if [ -f "$(PROXY_CONFIG)" ]; then \
			echo "使用代理配置..."; \
			source $(PROXY_CONFIG); \
		fi; \
		echo "尝试下载 SHA256SUMS 文件..."; \
		if command -v curl >/dev/null 2>&1; then \
			echo "使用 curl 下载..."; \
			$(call with_proxy)curl --connect-timeout 10 --max-time 30 -s "$(ISO_SHA256_URL)" | grep "$(ISO_FILENAME)" | cut -d' ' -f1 > $(ISO_SHA256_CACHE) 2>/dev/null; \
		else \
			echo "使用 wget 下载..."; \
			$(call with_proxy)wget --timeout=10 --tries=2 -q -O- "$(ISO_SHA256_URL)" | grep "$(ISO_FILENAME)" | cut -d' ' -f1 > $(ISO_SHA256_CACHE) 2>/dev/null; \
		fi; \
		if [ -s "$(ISO_SHA256_CACHE)" ]; then \
			echo "已缓存 SHA256: $$(cat $(ISO_SHA256_CACHE))"; \
		else \
			echo "错误: 无法获取 $(ISO_FILENAME) 的校验和"; \
			echo "请检查网络连接、代理设置或手动设置 SHA256 值"; \
			rm -f $(ISO_SHA256_CACHE); \
			exit 1; \
		fi; \
	else \
		echo "使用缓存的 SHA256: $$(cat $(ISO_SHA256_CACHE))"; \
	fi

.PHONY: check-download
check-download: get-official-sha256
	@echo "检查下载文件完整性..."
	@if [ ! -f "$(ISO_FILENAME)" ]; then \
		echo "错误: ISO 文件不存在"; \
		exit 1; \
	fi
	@echo "检查文件大小..."
	@ACTUAL_SIZE=$$(stat -c%s "$(ISO_FILENAME)" 2>/dev/null || echo "0"); \
	if [ "$$ACTUAL_SIZE" -lt 1000000000 ]; then \
		echo "错误: 文件大小异常 ($$ACTUAL_SIZE 字节)"; \
		exit 1; \
	fi; \
	echo "文件大小: $$ACTUAL_SIZE 字节"
	@echo "验证 SHA256 校验和..."
	@EXPECTED_SHA256=$$(cat $(ISO_SHA256_CACHE)); \
	ACTUAL_SHA256=$$(sha256sum "$(ISO_FILENAME)" | cut -d' ' -f1); \
	if [ "$$ACTUAL_SHA256" = "$$EXPECTED_SHA256" ]; then \
		echo "✓ SHA256 校验和验证通过"; \
	else \
		echo "✗ SHA256 校验和不匹配"; \
		echo "期望: $$EXPECTED_SHA256"; \
		echo "实际: $$ACTUAL_SHA256"; \
		exit 1; \
	fi

.PHONY: download
download:
	@echo "智能下载检查..."
	@if [ -f "$(ISO_FILENAME)" ]; then \
		echo "ISO 文件已存在，验证完整性..."; \
		if $(MAKE) check-download >/dev/null 2>&1; then \
			echo "✓ ISO 文件已存在且完整，跳过下载"; \
		else \
			echo "文件校验失败，需要重新下载"; \
			rm -f "$(ISO_FILENAME)"; \
		fi; \
	else \
		echo "下载 ISO 文件..."; \
		sudo apt update && sudo apt install -y wget curl; \
		if [ -f "$(PROXY_CONFIG)" ]; then \
			echo "使用代理下载..."; \
			source $(PROXY_CONFIG); \
		fi; \
		$(call with_proxy)wget -c $(ISO_URLBASE)/$(ISO_FILENAME) || { \
			echo "下载失败"; \
			rm -f "$(ISO_FILENAME)"; \
			exit 1; \
		}; \
		echo "验证文件完整性..."; \
		$(MAKE) check-download; \
	fi

.PHONY: verify-only
verify-only:
	@if [ ! -f "$(ISO_FILENAME)" ]; then \
		echo "错误: ISO 文件不存在，请先下载"; \
		exit 1; \
	fi
	@$(MAKE) check-download

.PHONY: init
init:
	@echo "初始化 ISO 解压环境..."
	sudo apt install xorriso rsync
	( test -d $(ISO_ROOT) && mv -f $(ISO_ROOT) $(ISO_ROOT).$(shell date +%Y%m%d.%H%M%S) ) || true
	mkdir -p $(ISO_ROOT)
	sudo mkdir -p $(ISO_MOUNTPOINT)
	(mountpoint $(ISO_MOUNTPOINT) && sudo umount -q $(ISO_MOUNTPOINT)) || true
	sudo mount -o ro,loop $(ISO_FILENAME) $(ISO_MOUNTPOINT)
	rsync -av $(ISO_MOUNTPOINT)/. $(ISO_ROOT)/.
	sudo umount $(ISO_MOUNTPOINT)
	@echo "✓ ISO 解压完成到 $(ISO_ROOT)"

.PHONY: setup
setup:
	@echo "设置 autoinstall 配置..."
	@if [ ! -d "$(ISO_ROOT)" ]; then \
		echo "错误: ISO_ROOT 目录 $(ISO_ROOT) 不存在"; \
		echo "请先运行 'make init' 解压ISO"; \
		exit 1; \
	fi
	# 确保目录可写
	chmod -R u+w $(ISO_ROOT)
	# 智能选择配置文件
	@if [ -f "$(USERDATA_SRC)" ]; then \
		echo "使用默认配置: $(USERDATA_SRC)"; \
		cp -f $(USERDATA_SRC) $(USERDATA_DEST); \
	elif [ -f "config/user-data.efi" ]; then \
		echo "使用 UEFI 配置: config/user-data.efi"; \
		cp -f config/user-data.efi $(USERDATA_DEST); \
	elif [ -f "config/user-data.mbr" ]; then \
		echo "使用 MBR/BIOS 配置: config/user-data.mbr"; \
		cp -f config/user-data.mbr $(USERDATA_DEST); \
	else \
		echo "错误: 未找到任何配置文件 (user-data, user-data.efi, user-data.mbr)"; \
		exit 1; \
	fi
	cp -f $(METADATA_SRC) $(METADATA_DEST)
	# 复制 grub.cfg
	cp -f config/boot/grub/grub.cfg $(ISO_ROOT)/boot/grub/grub.cfg
	# 添加额外文件
	rsync -av $(EXTRAS_SRCDIR)/. $(EXTRAS_DESTDIR)/.
	@echo "✓ autoinstall 配置设置完成"

# 主要的 ISO 生成目标 - 使用优化的 xorriso 命令
.PHONY: geniso
geniso: setup
	@echo "生成 autoinstall ISO 使用优化的 xorriso 方法..."
	@echo "原始 ISO: $(ISO_FILENAME)"
	@echo "输出 ISO: $(GENISO_FILENAME)"
	@echo "修改时间: $(GENISO_MODIFICATION_DATE)"
	sudo env LANG=$(GENISO_LANG) xorriso -as mkisofs \
		-V '$(GENISO_VOLID)' \
		--modification-date='$(GENISO_MODIFICATION_DATE)' \
		--grub2-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:"$(ISO_FILENAME)" \
		--protective-msdos-label \
		-partition_cyl_align off \
		-partition_offset 16 \
		--mbr-force-bootable \
		-append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b --interval:local_fs:6264708d-6274851d::"$(ISO_FILENAME)" \
		-appended_part_as_gpt \
		-iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
		-c '/boot.catalog' \
		-b '/boot/grub/i386-pc/eltorito.img' \
		-no-emul-boot \
		-boot-load-size 4 \
		-boot-info-table \
		--grub2-boot-info \
		-eltorito-alt-boot \
		-e '--interval:appended_partition_2_start_1566177s_size_10144d:all::' \
		-no-emul-boot \
		-boot-load-size 10144 \
		-o "$(GENISO_FILENAME)" \
		"$(ISO_ROOT)/"
	@echo "✓ autoinstall ISO 生成完成: $(GENISO_FILENAME)"
	@echo ""
	@echo "使用方法:"
	@echo "  1. 将 ISO 写入 USB: sudo dd if=$(GENISO_FILENAME) of=/dev/sdX bs=4M status=progress"
	@echo "  2. 或在虚拟机中使用该 ISO 文件进行自动安装"

.PHONY: clean-all
clean-all: unset-proxy
	@echo "清理工作目录和生成的ISO文件..."
	# 删除工作目录（避免污染原始ISO内容）
	rm -rf "$(ISO_ROOT)"
	# 删除生成的自定义ISO文件（保留原始ISO）
	find . -name "ubuntu-custom-autoinstaller.*.iso" -delete 2>/dev/null || true
	@echo "已保留原始ISO文件: $(ISO_FILENAME)"
	@echo "清理完成"

.PHONY: status
status:
	@echo "=== 文件状态检查 ==="
	@if [ -f "$(ISO_FILENAME)" ]; then \
		ACTUAL_SIZE=$$(stat -c%s "$(ISO_FILENAME)" 2>/dev/null || echo "0"); \
		echo "ISO 文件: 存在 ($$ACTUAL_SIZE 字节)"; \
	else \
		echo "ISO 文件: 不存在"; \
	fi
	@if [ -f "$(ISO_SHA256_CACHE)" ]; then \
		echo "SHA256 缓存: 存在 ($$(cat $(ISO_SHA256_CACHE)))"; \
	else \
		echo "SHA256 缓存: 不存在"; \
	fi
	@if [ -d "$(ISO_ROOT)" ]; then \
		echo "工作目录: 存在 ($(ISO_ROOT))"; \
	else \
		echo "工作目录: 不存在"; \
	fi
	@$(MAKE) proxy-status

# 帮助信息
.PHONY: help
help:
	@echo "Ubuntu 自动安装 ISO 制作工具"
	@echo ""
	@echo "使用流程:"
	@echo "  1. make download     - 下载官方 ISO"
	@echo "  2. make init         - 解压 ISO 到工作目录"
	@echo "  3. make geniso       - 生成 autoinstall ISO"
	@echo ""
	@echo "主要命令:"
	@echo "  download        - 智能下载 ISO 文件"
	@echo "  verify-only     - 仅验证现有文件"
	@echo "  init            - 解压 ISO 到工作目录"
	@echo "  setup           - 设置 autoinstall 配置"
	@echo "  geniso          - 生成 autoinstall ISO"
	@echo "  status          - 显示所有文件状态"
	@echo "  clean-all       - 清理所有文件和配置"
	@echo ""
	@echo "代理设置:"
	@echo "  set-proxy PROXY=<地址>   - 设置代理"
	@echo "  unset-proxy              - 取消代理"
	@echo "  proxy-status             - 显示代理状态"
	@echo ""
	@echo "代理示例:"
	@echo "  make set-proxy PROXY=http://127.0.0.1:7890"
	@echo "  make set-proxy PROXY=socks5://127.0.0.1:1080"
	@echo ""
	@echo "完整示例:"
	@echo "  make download && make init && make geniso"

# 默认目标
.DEFAULT_GOAL := help


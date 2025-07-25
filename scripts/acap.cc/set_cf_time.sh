#!/bin/bash

# systemd Timer 自动配置脚本
set -e

SERVICE_NAME="cf-update-dns"
SCRIPT_PATH="/root/acap.cc/cf_update_dns.sh"  # 直接使用 /root

# 检查 root 权限
[[ $EUID -ne 0 ]] && { echo "需要 root 权限，请使用 sudo"; exit 1; }

# 检查脚本存在
[[ ! -f "$SCRIPT_PATH" ]] && { echo "脚本不存在: $SCRIPT_PATH"; exit 1; }

echo "配置 systemd timer..."

# 停止现有服务
systemctl stop "${SERVICE_NAME}.timer" 2>/dev/null || true
systemctl disable "${SERVICE_NAME}.timer" 2>/dev/null || true

# 创建 service 文件
cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=Cloudflare DNS Update Script
After=network.target

[Service]
Type=oneshot
User=root
WorkingDirectory=/root
Environment=HOME=/root
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EnvironmentFile=/lab/envs/cf.env
ExecStart=/bin/bash -c '. ${SCRIPT_PATH}'
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}
EOF

# 创建 timer 文件
cat > "/etc/systemd/system/${SERVICE_NAME}.timer" << EOF
[Unit]
Description=Run CF DNS Update every 5 minutes
Requires=${SERVICE_NAME}.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 启动服务
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.timer"
systemctl start "${SERVICE_NAME}.timer"

echo "✅ 配置完成！"
echo "查看状态: systemctl status ${SERVICE_NAME}.timer"
echo "查看日志: journalctl -u ${SERVICE_NAME}.service -f"
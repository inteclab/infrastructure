# 安装 caddy
# 清理之前的文件
sudo rm -f /usr/local/bin/caddy
rm -f /tmp/caddy*

# 检测架构并下载正确版本
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    CADDY_ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    CADDY_ARCH="arm64"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi

echo "检测到架构: $ARCH，下载 $CADDY_ARCH 版本"

# 直接下载 Caddy v2.10.0
curl -L "https://github.com/caddyserver/caddy/releases/download/v2.10.0/caddy_2.10.0_linux_${CADDY_ARCH}.tar.gz" -o /tmp/caddy.tar.gz

# 验证下载
if [ ! -f /tmp/caddy.tar.gz ]; then
    echo "下载失败，文件不存在"
    exit 1
fi

# 检查文件大小
FILE_SIZE=$(stat -c%s /tmp/caddy.tar.gz)
if [ "$FILE_SIZE" -lt 1000 ]; then
    echo "下载的文件太小，可能下载失败"
    cat /tmp/caddy.tar.gz
    exit 1
fi

echo "下载成功，文件大小: $FILE_SIZE 字节"

# 解压
cd /tmp
tar -xzf caddy.tar.gz

# 验证二进制文件
if [ ! -f caddy ]; then
    echo "解压失败，caddy 文件不存在"
    ls -la /tmp/
    exit 1
fi

# 检查文件类型
file caddy

# 安装到系统路径
sudo mv caddy /usr/local/bin/
sudo chmod +x /usr/local/bin/caddy

# 创建 caddy 用户和组（如果不存在）
if ! id "caddy" &>/dev/null; then
    sudo groupadd --system caddy
    sudo useradd --system --gid caddy --create-home --home-dir /var/lib/caddy --shell /usr/sbin/nologin caddy
fi

# 创建必要的目录
sudo mkdir -p /etc/caddy
sudo mkdir -p /var/lib/caddy
sudo mkdir -p /usr/share/caddy

# 设置权限
sudo chown -R caddy:caddy /var/lib/caddy
sudo chown -R root:caddy /etc/caddy

# 创建 systemd 服务文件
sudo tee /etc/systemd/system/caddy.service > /dev/null <<'EOF'
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/local/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=1048576
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

# 创建默认配置文件
sudo tee /etc/caddy/Caddyfile > /dev/null <<'EOF'
:80 {
    root * /usr/share/caddy
    file_server
}
EOF

# 创建默认网页
sudo tee /usr/share/caddy/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Caddy!</title>
</head>
<body>
    <h1>Congratulations!</h1>
    <p>Your Caddy web server is successfully installed and working.</p>
</body>
</html>
EOF

# 设置文件权限
sudo chown caddy:caddy /usr/share/caddy/index.html

# 重新加载 systemd
sudo systemctl daemon-reload

# 启动并启用 Caddy 服务
sudo systemctl start caddy
sudo systemctl enable caddy

# 验证安装
echo "验证 Caddy 安装："
caddy version
echo ""
echo "检查服务状态："
sudo systemctl status caddy --no-pager -l
echo ""
echo "测试配置文件："
sudo caddy validate --config /etc/caddy/Caddyfile